# frozen_string_literal: true

Rails.application.routes.draw do
  root 'cluster#show'

  resource :cluster, only: :show, controller: :cluster
  resource :hunter, only: :show, controller: :hunter

  namespace :configure do
    get '/', to: redirect('')
    get 'groups', to: redirect('')
    get 'nodes', to: redirect('')

    configure_actions = [:show, :update, :destroy]
    resource :domain, controller: :domain, only: configure_actions
    resources :groups, only: configure_actions
    resources :nodes, only: configure_actions
  end
end
