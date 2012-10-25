require 'grit'


module Grit
  class Repo
    def repo_name
      File.basename(self.path, '.git')
    end
  end
end

enable :sessions
use Rack::MethodOverride

set :username,'Bond'
set :token,'shakenN0tstirr3d'
set :password,'007'
set :reporoot, '/Users/rsstorg/Programs/ruby/sinatra/webgit/transient/repos'

helpers do
  def admin?
  	request.cookies[settings.username] == settings.token
  end
  
  def protected!
  	redirect login_path unless admin? 
  end

  def root_path
  	"/"
  end

  def about_path
  	"/about"
  end

  def login_path
  	"/login"
  end

  def logout_path
  	"/logout"
  end

  def show_repo_path(r)
    "/repository/#{r.repo_name}"
  end

  def confirm_delete_repo_path(r)
    "/repository/#{r.repo_name}/delete"
  end
end

get '/login' do
  haml :login
end

get '/logout' do
	response.set_cookie(settings.username, false) 
	redirect root_path
end

post '/login' do
	if params['username']==settings.username&&params['password']==settings.password
		response.set_cookie(settings.username,settings.token) 
		redirect root_path
	else
		flash[:notice] = "Username or Password incorrect"
		redirect login_path
	end
end

get '/' do
	protected!
	@repos = Dir.open(settings.reporoot).to_a.select { |e| (e != '.') && (e != '..')}.collect{ |e| Grit::Repo.new("#{settings.reporoot}/#{e}")}
	haml :index
end

get '/about' do
  haml :about
end

get '/repositories/new' do
  haml :new_repository
end


post '/repository/create' do
	reponame = params[:reponame].gsub(/[^A-z]/,"_")
	path = settings.reporoot + "/" + reponame + ".git"
	throw :halt, [ 400, 'Repository exists' ] if File.exists? path
	Dir.mkdir path
	repo = Grit::Repo.init_bare(path)
	redirect root_path
end

get '/repository/:repo_name/delete' do |repo_name|
  @repo = Grit::Repo.new("#{settings.reporoot}/#{repo_name}.git")
  haml :confirm_delete
end

get '/repository/:repo_name' do |repo_name|
  @repo = Grit::Repo.new("#{settings.reporoot}/#{repo_name}.git")
  haml :show_repository
end


