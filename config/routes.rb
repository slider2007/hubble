Rails.application.routes.draw do
  get '/login' => 'sessions#new', as: 'login'
  post '/login' => 'sessions#create', as: 'login_submit'
  get '/logout' => 'sessions#destroy', as: 'logout'
  get '/password/forgot' => 'sessions#forgot_password', as: 'forgot_password'
  post '/password/reset' => 'sessions#reset_password', as: 'reset_password'
  get '/password/recover' => 'sessions#recover_password', as: 'recover_password'

  resources :users, only: %i{ new create update } do
    collection do
      get :welcome
      get :confirm
      get :confirmed
      get :settings
    end
  end

  # HUBBLE
  root to: 'home#index'

  concern :cosmoslike do
    resources :chains, format: false, constraints: { id: /[^\/]+/ }, only: %i{ show } do
      get '/dashboard' => 'dashboard#index', as: 'dashboard'

      resource :faucet, only: %i{ show } do
        resources :faucet_transactions, as: 'transactions', path: 'transactions', only: %i{ create }
      end

      member do
        get :search
        get :halted
        get :prestart
        post :broadcast
      end

      resources :events, only: %i{ index show }

      resources :validators, only: %i{ show } do
        resources :subscriptions, only: %i{ index create }, controller: '/util/subscriptions'
      end

      resources :accounts, only: %i{ show }

      resources :blocks, only: %i{ show } do
        resources :transactions, only: %i{ show }
      end
      resources :transactions, only: %i{ show }

      resources :logs, only: %i{ index }, controller: '/util/logs'

      namespace :governance do
        root to: 'main#index'
        resources :proposals, only: %i{ show }
      end

      resources :watches, as: 'watches', only: %i{ create }
    end
  end

  get '/chains/*path', to: redirect('/cosmos/chains/%{path}')

  namespace :cosmos, network: 'cosmos' do concerns :cosmoslike end
  namespace :terra, network: 'terra' do concerns :cosmoslike end
  namespace :iris, network: 'iris' do concerns :cosmoslike end
  namespace :kava, network: 'kava' do concerns :cosmoslike end
  namespace :emoney, network: 'emoney' do concerns :cosmoslike end

  namespace :near, network: 'near' do
    resources :chains, constraints: { id: /[^\/]+/ } do
      member do
        get :show
        get :search
      end

      resources :validators, only: :show, constraints: { id: /[^\/]+/ }
    end
    root to: 'chains#show'
  end

  namespace :oasis, network: 'oasis' do
    resources :chains, only: %i{ show } do
      get '/dashboard' => 'dashboard#index', as: 'dashboard'

      member do
        get :search
      end

      resources :blocks, only: %i{ show } do
        resources :transactions, only: %i{ show }
      end
      resources :validators, only: %i{ show } do
        resources :subscriptions, only: %i{ index create }, controller: '/util/subscriptions'
      end
    end
  end

  namespace :livepeer, network: 'livepeer' do
    resources :chains, format: false, constraints: { id: /[^\/]+/ }, only: %i{ show } do
      get '/dashboard' => 'dashboard#index', as: 'dashboard'
      get :search, on: :member

      resources :events, only: %i{ index show }

      resources :rounds, only: %i{ show }, param: :number
      resources :transcoders, only: %i{ show }, param: :address

      resources :delegator_lists do
        resource :report, only: %i{ new show }
        resources :subscriptions, only: %i{ index create }
        resources :events, controller: :delegator_list_events
      end
    end
  end

  namespace :tezos do
    resources :searches, only: :create
    resources :bakers, only: :show do
      resources :subscriptions, only: [:create, :destroy], shallow: true
    end
    resources :cycles, only: :show do
      resources :baker_events, only: :index
    end
    namespace :governance, only: :index do
      root to: 'main#index'
      resources :proposals, only: :show
    end
    get '/charts/baker_history/:baker_id', to: 'charts#baker_history'
    root to: 'cycles#show'
  end

  namespace :polkadot, network: 'polkadot' do
    resources :chains do
      get :search, on: :member # Not implemented yet but used by view to generate a path
      get '/dashboard' => 'dashboard#index', as: 'dashboard'

      resources :blocks, only: :show  do
        resources :transactions
      end
      resources :accounts, only: :show
    end
  end

  namespace :telegram do
    resource :account, only: %i{ show create destroy }
    post '/webhooks/:token', to: 'webhooks#create'
  end

  # ADMIN
  namespace :admin do
    root to: 'main#index'

    resources :sessions, only: %i{ new create }
    get '/logout' => 'sessions#destroy', as: 'logout'

    resources :administrators do
      collection do
        get :setup
        post :setup
      end
    end

    resources :users do
      member do
        get :masq
      end
      resources :alert_subscriptions, only: %i{ destroy }
    end

    concern :cosmoslike do
      resources :chains, format: false, constraints: { id: /[^\/]+/ } do
        resource :faucet, only: %i{ show update destroy }
        resources :faucets, only: %i{ create }

        resources :validator_events, only: %i{ index }

        member do
          post :move_up
          post :move_down
        end
      end
    end

    namespace :cosmos do concerns :cosmoslike end
    namespace :terra do concerns :cosmoslike end
    namespace :iris do concerns :cosmoslike end
    namespace :kava do concerns :cosmoslike end
    namespace :emoney do concerns :cosmoslike end

    namespace :oasis do
      resources :chains, format: false, constraints: { id: /[^\/]+/ } do
        member do
          post :move_up
          post :move_down
        end
      end
    end

    namespace :livepeer do
      resources :chains, format: false, constraints: { id: /[^\/]+/ }, except: %i{ index edit } do
        member do
          post :move_up
          post :move_down
        end
      end
    end

    namespace :tezos do
      resources :chains, except: [:index] do
        member do
          post :move_up
          post :move_down
        end
      end
    end

    namespace :near do
      resources :chains, except: [:index]
    end

    namespace :polkadot do
      resources :chains, except: [:index]
    end

    namespace :common do
      resources :validator_events, only: %i{ destroy }
    end
  end

  mount LetterOpenerWeb::Engine, at: '/_mail' if Rails.env.development?
  match '*path', to: 'home#catch_404', via: :all
end
