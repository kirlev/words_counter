Rails.application.routes.draw do
  post '/analyze-text', to: 'text_analyzer#analyze'
  get 'words/:name', to: 'words#show'
end
