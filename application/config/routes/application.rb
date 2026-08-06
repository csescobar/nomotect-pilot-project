resources :organizations, only: [] do
  resources :service_requests, except: :destroy do
    member do
      patch :transition
      patch :assign
      post :attach
    end
  end
end
