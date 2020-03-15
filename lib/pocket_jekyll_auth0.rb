require 'pocket_jekyll_auth0/version'
require 'jekyll'
require 'auth0_machine_to_machine'
require 'uri'
require 'net/http'

class JekyllPocketError < StandardError; end

class NetworkError < JekyllPocketError; end

module PocketJekyllAuth0
  class Tag < Liquid::Tag
    def self.cache
      @cache ||= Jekyll::Cache.new('PocketJekyllAuth0')
    end

    def self.attemptListCacheClear(site)
      config = site.config['jekyll-pocket']
      config_pocket_api = config['pocket-api-config']

      if config_pocket_api['cache-clear-on-initialize']
        puts 'Clearing cache on pre_render.'
        cache.delete 'pocket_list' if cache.key? 'pocket_list'
      end
    end

    def getTokenObject(config_auth0)
      begin
        ::Auth0MachineToMachine::Client.new.getM2M!(config_auth0)
      rescue Exception => e
        puts 'Could not authenticate with Auth0.', e
        false
      end
    end

    def fillTokenCache(config_auth0)
      token_object = getTokenObject(config_auth0)

      if token_object != false
        cache = PocketJekyllAuth0::Tag.cache

        return cache['token_object'] = token_object
      end

      false
    end

    def getFillTokenCache(config_auth0)
      cache = PocketJekyllAuth0::Tag.cache

      if !cache.key?('token_object')
        fillTokenCache(config_auth0)
      else
        token_object = cache['token_object']
        if Time.now <= token_object[:expire_date]
          return token_object
        end

        fillTokenCache(config_auth0)
      end
    end

    def fillPocketList(bearer_token, pocket_api_url, pocket_list_filter)
      cache = PocketJekyllAuth0::Tag.cache

      url = URI(pocket_api_url)

      http = Net::HTTP.new(url.host, url.port)
      use_ssl = url.scheme == 'https'
      http.use_ssl = use_ssl
      if use_ssl
        http.verify_mode = OpenSSL::SSL::VERIFY_PEER
      else
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      end

      request = Net::HTTP::Post.new(url)
      request['content-type'] = 'application/json'
      request['accept'] = 'application/json'
      request['authorization'] = "Bearer #{bearer_token}"

      body = pocket_list_filter

      puts "Requesting Pocket list with filters #{pocket_list_filter.to_json}."

      request.body = body.to_json

      begin
        response = http.request(request)

        if response.is_a?(Net::HTTPSuccess)
          list = JSON.parse(response.body)
          download_date = Time.now

          return cache['pocket_list'] = {
            list: list['list'],
            download_date: download_date
          }
        else
          puts response
          raise NetworkError.new response
        end
      rescue Exception => e
        puts e
      end

      false
    end

    def getFillPocketList(bearer_token, pocket_api_url, pocket_list_filter, cache_timeout)
      cache = PocketJekyllAuth0::Tag.cache 

      if !cache.key?('pocket_list')
        puts "pocket_list key not in cache. Trying to fill."
        return fillPocketList(bearer_token, pocket_api_url, pocket_list_filter)
      else
        pocket_list = cache['pocket_list']
        if (Time.now - cache_timeout) <= pocket_list[:download_date]
          return pocket_list
        end

        puts "pocket_list key expired. Trying to fill with new data."

        fillPocketList(bearer_token, pocket_api_url, pocket_list_filter)
      end
    end

    def getTemplate
      custom_template_path = File.join Dir.pwd, '_includes', 'pocket.html'

      if File.exist?(custom_template_path)
        template = File.read custom_template_path
      else
        template_path = File.join __dir__, '_includes', 'pocket.html'
        template = File.read template_path
      end

      Liquid::Template.parse template
    end

    def renderTemplate(context, pocket_list)
      site = context.registers[:site]
      payload = Jekyll::Utils.deep_merge_hashes(
        site.site_payload,
        # Copy context['page'] from Jekyll to pocket.html template context so it's available for custom Liquid tags inside it like jekyll-timeago.
        'page' => context['page'],
        'pocket_list' => pocket_list
      )
      getTemplate.render!(payload)
    end

    def preparePocketListForTemplate raw_list
      raw_list
        .map { |item_id, item_value| item_value }
        .sort_by { |item_value| item_value['time_updated'] }
        .map do |item_value|
          item_value.map do |item_value_key, item_value_value|
            if item_value_key =~ /\Atime_/
              [item_value_key, Time.at(item_value_value.to_i)]
            else
              [item_value_key, item_value_value]
            end
          end
          .to_h
        end
    end

    def render(context)
      site = context.registers[:site]
      config = site.config['jekyll-pocket']
      config_auth0 = config['auth0-config']
      config_pocket_api = config['pocket-api-config']

      # TODO: Use value from config for cache timeouts.
      # TODO: Invalidate caches when configuration in _config.yml changes.

      token_object = getFillTokenCache(config_auth0)

      if token_object
        puts "Auth0 token object received. Object expiration date is #{token_object[:expire_date]}."

        bearer_token = token_object[:access_token]
        pocket_api_url = config_pocket_api['url']

        puts "Fetching list from Pocket service."

        pocket_list_filter_allowed_keys = ['offset', 'count', 'state', 'favorite', 'tag', 'contentType', 'sort', 'search', 'domain', 'since']
        pocket_list_filter = config_pocket_api.select { |config_key, config_value| pocket_list_filter_allowed_keys.include? config_key }

        cache_timeout = config_pocket_api['cache-timeout']

        pocket_list = getFillPocketList(bearer_token, pocket_api_url, pocket_list_filter, cache_timeout)

        if pocket_list != false
          # TODO: Only get new bearer token when current was rejected instead of getting it on every error.
          token_object = getFillTokenCache(context)
          pocket_list = getFillPocketList(bearer_token, pocket_api_url, pocket_list_filter, cache_timeout)[:list]

          ordered_pocket_list = preparePocketListForTemplate(pocket_list)

          render = renderTemplate(context, ordered_pocket_list)
        else
          render = renderTemplate(context, [])
        end
      else
        render = renderTemplate(context, [])
      end
    end

    Liquid::Template.register_tag "pocket", self

    Jekyll::Hooks.register :site, :pre_render do |site|
      self.attemptListCacheClear site
    end
  end
end