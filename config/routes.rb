Rails.application.routes.draw do
  get 'password_resets/new'

  get 'sessions/new'

  root 'welcome#index'

  post 'welcome/apply' => 'welcome#apply'

  get 'signup' => 'authy#new'
  post 'signup' => 'authy#create'
  get 'signup_part2' => 'authy#part2'
  post 'signup_part2' => 'authy#part2_verify'
  post 'signup_part2_resend' => 'authy#part2_resend'
  get 'signup_part3' => 'users#new'
  get 'confirm_email/:id' => 'users#confirm_email', as: :email_confirmation
  get 'login' => 'sessions#new'
  post 'login' => 'sessions#create'
  get 'verify' => 'sessions#code'
  post 'verify' => 'sessions#verify'
  post 'verify_resend' => 'sessions#resend'
  delete 'logout' => 'sessions#destroy'

  resources :password_resets

  get '/cards' => 'cards#new'
  post '/cards/update' => 'cards#update'
  post '/cards/create' => 'cards#create'
  post '/cards/select' => 'cards#select'
  post '/cards/delete' => 'cards#delete'

  get '/promotions' => 'promotions#show'
  post '/promotions/create' => 'promotions#create'
  post '/promotions/switch' => 'promotions#switch'
  post '/promotions/edit' => 'promotions#edit'
  post '/promotions/delete' => 'promotions#delete'
  post '/promotions/select' => 'promotions#select'
  post '/promotions/booking' => 'promotions#booking'
  post '/promotions/apply' => 'promotions#apply'
  get '/promotions/redeem' => 'promotions#redeem'
  post '/promotions/free' => 'promotions#free_visit'

  get '/dashboard' => 'oncall_times#index'
  post '/oncall_times/create' => 'oncall_times#create'
  post '/oncall_times/switch' => 'oncall_times#switch'

  post '/fee_schedules/create' => 'fee_schedules#create'
  post '/fee_schedules/select' => 'fee_schedules#select'
  post '/fee_schedules/fee_rule' => 'fee_schedules#fee_rule'
  post '/fee_schedules/edit' => 'fee_schedules#edit'


  post '/mailing_list' => 'subscription#mail'
  get '/unsubscribe_mail' => 'unsubscribe_mail#index'
  post '/unsubscribe_mail' => 'unsubscribe_mail#destroy'

  get '/house_calls' => 'landing#index'
  post '/house_calls/mailing' => 'landing#mailing'

  get '/subscribe/new' => 'subscription#new'
  post '/subscribe/create' => 'subscription#create'
  get '/subscribe' => 'subscription#index'
  get '/subscribe/edit' => 'subscription#edit'
  post '/subscribe/f2a0b1f7c5796fc8ff97d8fa20ada825' => 'subscription#webhook'
  # TODO: Make a not so obvious webhook route, for security reasons make it a random hash

  get '/sds/subscribers' => 'plans#subscribers'
  get '/sds' => 'plans#index'
  get '/sds/join' => 'plans#new'
  post '/sds/join' => 'plans#create'

  post 'doctors/new' => 'temporary_credentials#create'

  resources :doctors do
    get :autocomplete_medical_school_name, :on => :collection
    get :autocomplete_state_medical_board_name, :on => :collection
    get :autocomplete_specialty_name, :on => :collection
  end
  get 'stripe_seller/new' => 'stripe_seller#new'

  resources :temporary_credentials
  post 'doc_basic' => 'doctors#create'

  get 'visits' => 'visits#show'
  get 'office' => 'online_visits#show'
  get 'booking' => 'booking#new'
  post 'booking' => 'booking#create'
  post 'temporary_visit' => 'welcome#temporary_visit'

  get 'about' => 'about#show'
  get 'contact' => 'contact#show'
  get 'howitworks' => 'how_it_works#show'

  get '/landing/thankyou' => 'landing#thanks'

  match '/404', via: :all, to: 'errors#not_found'
  match '/422', via: :all, to: 'errors#unprocessable_entity'
  match '/500', via: :all, to: 'errors#server_error'

  match "test_exception", via: :all, to: "application#test_exception"
  post "sessions/fake_login" => 'sessions#fake_login'

  get '/chat_entries/latest/:connectionid', :to => 'chat_entries#latest'
  post '/chat_entries/add', :to => 'chat_entries#add'

  post 'visit_notifications' => 'visit_notifications#visit_sms'
  get 'visit_notifications' => 'visit_notifications#visit_sms'

  resources :shows
  get "/:id" => "users#show"
  resources :users
  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  # root 'welcome#index'

  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Example resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end

  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end
end
