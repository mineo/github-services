class Service::Slatebox < Service
  string :app_id, :token
  white_list :app_id

  def receive_push
    slugs = data['app_id']
    token = data['token']

    raise_config_error 'Missing app_id' if slugs.to_s.empty?
    raise_config_error 'Missing token' if token.to_s.empty?

    slugs.split(",").each do |slug|
      slug.strip!
      post_slatebox_message(slug, token)
    end
  end

private

  def post_slatebox_message(slug, token)
    return unless commit = distinct_commits.last
    create_build_url = "http://api.slatebox.com/application/build/#{slug}/#{token}"

    slatebox_message = {
      :branches => {
        ref_name => {
          :commit_id => commit['id'],
          :commit_message => commit['message'],
          :download_url => commit['url'].sub('commit', 'tarball')
        }
      }
    }

    http_post create_build_url, slatebox_message.to_json, 'Accept' => 'application/json'
  end
end
