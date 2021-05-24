include Mediators::Messages

RSpec.describe UserFinder, ".from_message" do
  def finder_from_message_type(type)
    message = instance_double(Message, target_type: type, target_id: SecureRandom.uuid)
    UserFinder.from_message(message)
  end

  it "creates a finder for messages targeting a user" do
    expect(finder_from_message_type("user")).to be_instance_of(UserUserFinder)
  end

  it "creates a finder for messages targeting an app" do
    expect(finder_from_message_type("app")).to be_instance_of(AppUserFinder)
  end

  it "creates a finder for messages targeting a dashboard" do
    expect(finder_from_message_type("dashboard")).to be_instance_of(AppUserFinder)
  end

  it "creates a finder for messages targeting an email" do
    expect(finder_from_message_type("email")).to be_instance_of(EmailUserFinder)
  end

  it "blows up on messages with strange types" do
    expect { finder_from_message_type("nonsense") }.to raise_error(RuntimeError)
  end
end

RSpec.describe UserUserFinder, "#call" do
  before do
    @id = SecureRandom.uuid
    stub_heroku_api
    @finder = UserUserFinder.new(target_id: @id)
  end

  it "creates the user locally if needed" do
    expect(User[heroku_id: @id]).to be_nil
    @finder.call
    user = User[heroku_id: @id]
    expect(user).to_not be_nil
    expect(user.email).to eq("username@example.com")
  end

  it "updates the email for the user" do
    User.create(heroku_id: @id, email: "outdated@email.com")
    @finder.call
    user = User[heroku_id: @id]
    expect(user.email).to eq("username@example.com")
  end

  it "returns an array of one user with role" do
    response = @finder.call
    expect(response).to be_kind_of(Array)
    expect(response.size).to eq(1)

    uwr = response.first
    expect(uwr.role).to eq(:self)
    expect(uwr.user.heroku_id).to eq(@id)
  end

  it "excludes users that have never logged in" do
    stub_heroku_api do
      get "/account" do
        MultiJson.encode(
          id: env["HTTP_USER"],
          email: "username@example.com",
          last_login: nil
        )
      end
    end

    response = @finder.call
    expect(response).to be_empty
  end

  it "excludes missing users" do
    stub_heroku_api do
      get "/account" do
        raise Excon::Errors::NotFound, "not found"
      end
    end

    response = @finder.call
    expect(response).to be_empty
  end
end

RSpec.describe AppUserFinder, "#call" do
  before do
    @id = SecureRandom.uuid
    @finder = AppUserFinder.new(target_id: @id)

    @owner_id = HerokuApiStub::OWNER_ID
    @collab1_id = HerokuApiStub::COLLAB1_ID
    @collab2_id = HerokuApiStub::COLLAB2_ID

    stub_heroku_api
  end

  it "creates users locally if needed" do
    expect(User[heroku_id: @owner_id]).to be_nil
    expect(User[heroku_id: @collab1_id]).to be_nil
    expect(User[heroku_id: @collab2_id]).to be_nil
    @finder.call

    owner = User[heroku_id: @owner_id]
    expect(owner.email).to eq("username@example.com")
    collab1 = User[heroku_id: @collab1_id]
    expect(collab1.email).to eq("username2@example.com")
    collab2 = User[heroku_id: @collab2_id]
    expect(collab2.email).to eq("username3@example.com")
  end

  it "updates the email for users" do
    User.create(heroku_id: @owner_id, email: "outdated@email.com")
    @finder.call
    user = User[heroku_id: @owner_id]
    expect(user.email).to eq("username@example.com")
  end

  it "returns an array of users with roles" do
    result = @finder.call
    owner = result.detect { |uwr| uwr.role == :owner }
    expect(owner.user.heroku_id).to eq(@owner_id)

    collab1 = result.detect { |uwr| uwr.user.heroku_id == @collab1_id }
    expect(collab1.role).to eq(:collaborator)
  end

  it "fetches team owners" do
    stub_heroku_api do
      get "/apps/:id" do |id|
        MultiJson.encode(
          name: "example",
          owner: {
            id: SecureRandom.uuid,
            email: "team@herokumanager.com"
          }
        )
      end

      get "/teams/:name/members" do
        MultiJson.encode([
          {
            role: "admin",
            user: {
              id: SecureRandom.uuid,
              email: "someone@example.com"
            }
          },
          {
            role: "admin",
            user: {
              id: SecureRandom.uuid,
              email: "username2@example.com"
            }
          },
          {
            role: "member",
            user: {
              id: SecureRandom.uuid,
              email: "member@example.com"
            }
          }
        ])
      end
    end

    result = @finder.call
    emails = result.map { |role| role.user[:email] }

    expect(emails.uniq).to eql(emails)
    expect(emails).to include("someone@example.com")
    expect(emails).to include("username2@example.com")
    expect(emails).not_to include("member@example.com")
    expect(emails).not_to include("team@herokumanager.com")
  end

  it "excludes users who have never logged in" do
    stub_heroku_api do
      get "/account" do
        MultiJson.encode(
          id: env["HTTP_USER"],
          email: "someone@example.com",
          last_login: nil
        )
      end
    end

    response = @finder.call
    inactive_user = response.detect { |r| r.user.email == "username@example.com" }
    expect(inactive_user).to be_nil
  end

  it "excludes missing apps" do
    stub_heroku_api do
      get "/apps/:id" do |id|
        raise Excon::Errors::NotFound, "not found"
      end
    end

    response = @finder.call
    expect(response).to be_empty
  end

  it "excludes missing apps" do
    stub_heroku_api do
      get "/apps/:id" do |id|
        raise Excon::Errors::NotFound, "not found"
      end
    end

    response = @finder.call
    expect(response).to be_empty
  end

  it "handles missing team lookups" do
    stub_heroku_api do
      get "/apps/:id" do |id|
        MultiJson.encode(
          name: "example",
          owner: {
            id: SecureRandom.uuid,
            email: "team@herokumanager.com"
          }
        )
      end

      get "/teams/:name/members" do
        raise Excon::Errors::NotFound, "not found"
      end
    end
    result = @finder.call
    emails = result.map { |role| role.user[:email] }
    # only the collaborators
    expect(emails.sort).to eq(%w[username2@example.com username3@example.com])
  end

  it "handles missing collaborator lookups" do
    stub_heroku_api do
      get "/apps/:id/collaborators" do
        raise Excon::Errors::NotFound, "not found"
      end
    end

    result = @finder.call
    emails = result.map { |role| role.user[:email] }
    # only the owner since we got that on the first call
    expect(emails).to eq(%w[username@example.com])
  end
end

RSpec.describe EmailUserFinder, "#call" do
  before do
    @id = SecureRandom.uuid
    Fabricate(:recipient, email: "foo@bar.com", active: true, verified: true, app_id: @id)
    @finder = EmailUserFinder.new(target_id: @id)
  end

  it "does not create users" do
    @finder.call
    expect(User.count).to eq(0)
  end

  it "returns an array of one user with role" do
    response = @finder.call
    expect(response).to be_kind_of(Array)
    expect(response.size).to eq(1)

    uwr = response.first
    expect(uwr.role).to eq(:self)
    expect(uwr.user.email).to eq("foo@bar.com")
  end
end
