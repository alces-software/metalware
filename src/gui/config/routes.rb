# frozen_string_literal: true

Rails.application.routes.draw do
  root 'cluster#show'

  resource :cluster, only: :show, controller: :cluster
  resource :hunter, only: :show, controller: :hunter
end
