Sechzehn::Application.routes.draw do
  get "errors/file_not_found"
  get "errors/unprocessable"
  get "errors/internal_server_error"
  root 'sechzehn#show'
  match '/404', to: 'errors#file_not_found', via: :all
  match '/422', to: 'errors#unprocessable', via: :all
  match '/500', to: 'errors#internal_server_error', via: :all
  match '/please_enable_cookies', to: 'errors#please_enable_cookies', via: :all
  match '/maintenance', to: 'errors#maintenance', via: :all
  resources :users
  post '/guess', to: 'sechzehn#guess'
  get '/solution', to: 'sechzehn#solution'
  get '/leaderboard', to: 'sechzehn#leaderboard'
  get '/new', to: 'sechzehn#new'
  get '/sync', to: 'sechzehn#sync'
  get '/help', to: 'sechzehn#help'
  post '/chats', to: 'chats#save'
  get '/chats/show', to: 'chats#show'
  get '/chats/messages', to: 'chats#messages'
  get '/highscore/elo', to: 'sechzehn#highscore_elo'
  get '/highscore/points', to: 'sechzehn#highscore_points'
  get '/highscore/words', to: 'sechzehn#highscore_words'
  get '/highscore/points/percent', to: 'sechzehn#highscore_points_percent'
  get '/highscore/words/percent', to: 'sechzehn#highscore_words_percent'
  get '/highscore/points/rate', to: 'sechzehn#highscore_points_rate'
  get '/highscore/words/rate', to: 'sechzehn#highscore_words_rate'
  match '/signout', to: 'users#signout', via: 'delete'
  match '/signup', to: 'users#signup', via: 'get'
  get "sitemap.xml", to: 'sitemap#index', defaults: { format: 'xml' }

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
