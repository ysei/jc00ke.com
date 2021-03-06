%w(rubygems sinatra/base haml sass rack-flash yaml json).each { |r| require r }

class Site < Sinatra::Base

    set :haml,          { :format => :html5 }
    set :sessions,      true
    enable :static
    use Rack::Static,   :urls => %w(/images /javascripts /docs), :root => 'public'
    use Rack::Flash,    :accessorize => [ :notice, :error ]

    configure :development do
        Sinatra::Application.reset!
        use Rack::Reloader
    end

    before do
        @page = request.path_info.gsub(/\//, '')
    end

    helpers do

        def get_yaml
            File.open('public/docs/resume.yml') { |y| YAML::load y }
        end
        def split_url(url)
            txt, url = url.scan(/^(.*)\s\|\s(.*)$/)[0]
            "<a href=\"#{url}\">#{txt}</a>"
        end
        def cache(time=600)
            headers['Cache-Control'] = "public, max-age=#{time}" if Sinatra::Base.production?
        end
    end

    get '/' do
        @title  = "Welcome!"
        haml :index
    end

    get %r{/(styles|print).css} do |sheet|
        content_type 'text/css', :charset => 'utf-8'
        sass sheet.to_sym
    end

    get '/resume' do
        @title  = "My Resume/CV/Experience"
        @resume = get_yaml
        @info   = @resume['info']
        cache
        haml :resume
    end

    get %r{/resume.(yml|json|pdf)} do |ft|
        if ft == 'yml' || ft == 'pdf'
            send_file "public/docs/resume.#{ft}"
        else
            yml     = get_yaml
            content_type 'text/json'
            attachment 'resume.json'
            cache
            JSON.pretty_generate yml
        end
    end

    get '/5000' do
        @title = "My 5000th tweet"
        cache(3600)
        haml :'5000'
    end
    get '/contact' do
        @title  = "Let's chat"
        haml :contact
    end

    not_found do
        @title  = "Where are you?"
        haml :not_found
    end

    error do
        @title  = "Uh oh, something broke."
        haml :error
    end

end
