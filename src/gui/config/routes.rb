# frozen_string_literal: true

Rails.application.routes.draw do
  root 'cluster#show'

  resource :cluster, only: :show, controller: :cluster
  resource :hunter, only: [:show, :destroy], controller: :hunter do
    post :start, :'record-node'

    # For Intercooler polling.
    get :'new-detected-node-rows'
  end

  configure_actions = [:show, :create, :destroy]

  resource :domain, only: [] do
    resource :configure, controller: 'domain/configure', only: configure_actions
  end

  get 'groups/start-configure' => 'groups/configure#start'
  resources :groups, only: [] do
    resource :configure, controller: 'groups/configure', only: configure_actions

    resource :build, controller: 'groups/build', only: [:show, :destroy] do
      post :start, :shutdown

      # For Intercooler polling.
      get :cancel_button, :messages
    end
  end

  resources :nodes, only: [] do
    resource :configure, controller: 'nodes/configure', only: configure_actions

    resource :build, controller: 'nodes/build', only: [:show, :destroy] do
      post :start, :shutdown

      # For Intercooler polling.
      get :cancel_button, :messages
    end

    post :'power-reset'
  end
end
