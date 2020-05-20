Rails.application.routes.draw do
  # Routes that are common for all API versions
  concern :api_base do
    resources :users do
      resources :games
    end
  end

  scope 'api' do
    namespace 'v1' do
      concerns :api_base
    end

    # Future work
#     namespace 'v2' do
#       concerns :api_base
#     end
  end
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
end
