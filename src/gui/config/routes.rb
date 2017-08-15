# frozen_string_literal: true

Rails.application.routes.draw do
  root 'cluster#show'

  resource :cluster, only: :show, controller: :cluster
  resource :hunter, only: :show, controller: :hunter

  configure_actions = [:show, :update, :destroy]

  resource :domain, only: [] do
    resource :configure, controller: 'domain/configure', only: configure_actions
  end

  get 'groups/start-configure' => 'groups/configure#start'
  resources :groups, only: [] do
    resource :configure, controller:  'groups/configure', only: configure_actions
    resource :build, controller:  'groups/build', only: :show
  end

  resources :nodes, only: [] do
    resource :configure, controller:  'nodes/configure', only: configure_actions
    resource :build, controller:  'nodes/build', only: :show
  end
end
