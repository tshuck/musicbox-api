Rails.application.routes.draw do

  mount ActionCable.server => '/cable'

  scope path: '/api' do
    resources :docs, only: [:index], path: '/swagger'

    scope path: '/v1' do
      resources :users
      resources :rooms, only: [:show] do
        resources :songs, only: [:create]
      end
    end
  end
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
