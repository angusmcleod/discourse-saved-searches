# frozen_string_literal: true

# name: discourse-saved-searches
# about: Saved Searches Plugin
# version: 0.1
# authors: Neil Lalonde
# url: https://github.com/discourse/discourse-saved-searches

enabled_site_setting :saved_searches_enabled

register_asset 'stylesheets/saved-searches.scss'

after_initialize do

  plugin = self

  require_dependency File.expand_path('../app/jobs/regular/saved_search_notification.rb', __FILE__)
  require_dependency File.expand_path('../app/jobs/scheduled/schedule_saved_searches.rb', __FILE__)

  User.register_custom_field_type('saved_searches', :json)
  User.register_custom_field_type('saved_tag_searches', :json)

  add_to_serializer(:user, :saved_searches, false) do
    (object.custom_fields['saved_searches'] || {})['searches']
  end

  add_to_serializer(:user, :saved_tag_searches, false) do
    (object.custom_fields['saved_tag_searches'] || {})['tag_searches']
  end

  add_to_serializer(:user, :include_saved_searches?, false) do
    plugin.enabled? && scope.can_edit?(object)
  end

  module ::SavedSearches
    class Engine < ::Rails::Engine
      engine_name 'saved_searches'
      isolate_namespace SavedSearches
    end
  end

  require_dependency 'application_controller'

  class ::SavedSearches::SavedSearchesController < ::ApplicationController
    requires_plugin 'discourse-saved-searches'

    def update
      if params[:searches]
        current_user.custom_fields['saved_searches'] = { "searches" => params[:searches] }
        current_user.save
      else
        UserCustomField.where(name: 'saved_searches', user_id: current_user.id).first&.destroy
      end
      if params[:tag_searches]
        current_user.custom_fields['saved_tag_searches'] = { "tag_searches" => params[:tag_searches] }
        current_user.save # TODO: save only once
      else
        UserCustomField.where(name: 'saved_tag_searches', user_id: current_user.id).first&.destroy
      end
      render json: success_json
    end
  end

  SavedSearches::Engine.routes.draw do
    resource :saved_searches, only: [:update]
  end

  Discourse::Application.routes.prepend do
    mount ::SavedSearches::Engine, at: '/'
  end
end

Discourse::Application.routes.append do
  # USERNAME_ROUTE_FORMAT is deprecated but we may need to support it for older installs
  username_route_format = defined?(RouteFormat) ? RouteFormat.username : USERNAME_ROUTE_FORMAT
  get '/u/:username/preferences/saved-searches' => 'users#preferences', constraints: { username: username_route_format }
end
