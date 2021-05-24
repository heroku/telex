module Middleware
  RSpec.describe ProducerAuthenticator do
    include HerokuAPIMock

    subject(:auther) { UserAuthenticator.new(app) }
    let(:app) { double(:app) }
    let(:rack_env) { {} }
    let(:rack_auth) { double(:auth) }

    describe "#call" do
      before do
        expect(Rack::Auth::Basic::Request).to receive(:new)
          .at_least(:once).with(rack_env).and_return(rack_auth)

        stub_request(:get, /heroku/).to_return(status: 403)
      end

      describe "with various things wrong" do
        it "raises Unauthorized if no credentials are provided" do
          allow(rack_auth).to receive_messages(provided?: false, basic?: true, credentials: nil)
          expect { auther.call(rack_env) }.to raise_error(Pliny::Errors::Unauthorized)
        end

        it "raises Unauthorized if no malformed credentials are provided" do
          allow(rack_auth).to receive_messages(provided?: true, basic?: true, credentials: ["", "some malformed key"])
          expect { auther.call(rack_env) }.to raise_error(Pliny::Errors::Unauthorized)
        end

        it "raises Unauthorized when incorrect credentials are provided" do
          allow(rack_auth).to receive_messages(provided?: true, basic?: true, credentials: ["", "invalid-key"])
          expect { auther.call(rack_env) }.to raise_error(Pliny::Errors::Unauthorized)
        end

        it "raises Unauthorized for auth other than basic auth" do
          valid_key = create_heroku_user.api_key
          allow(rack_auth).to receive_messages(provided?: false, basic?: false, credentials: ["", valid_key])
          expect { auther.call(rack_env) }.to raise_error(Pliny::Errors::Unauthorized)
        end
      end

      describe "with correct credentials" do
        let(:user_info) { create_heroku_user }

        before do
          expect(app).to receive(:call).at_least(:once).with(rack_env)
          allow(rack_auth).to receive_messages(provided?: true, basic?: true, credentials: ["", user_info.api_key])
        end

        it "finds the right user with matching heroku_id" do
          existing_user = User.create(heroku_id: user_info.heroku_id, email: user_info.email)
          auther.call(rack_env)
          current_user = Pliny::RequestStore.store[:current_user]

          expect(current_user).to_not be_nil
          expect(current_user.heroku_id).to eq(user_info.heroku_id)
          expect(current_user.id).to eq(existing_user.id)
        end

        it "creates a local user if they don't exist yet" do
          expect {
            auther.call(rack_env)
          }.to change(User, :count).by(1)
          expect(Pliny::RequestStore.store[:current_user]).to_not be_nil
          expect(Pliny::RequestStore.store[:current_user].heroku_id).to eq(user_info.heroku_id)
        end

        describe "caching" do
          it "caches the user so only the first request makes a call to API" do
            allow(Config).to receive(:cache_user_auth?).and_return(true)
            2.times { auther.call(rack_env) }
            expect(a_request(:any, %r{api.heroku.com})).to have_been_made.once
          end

          it "doesn't cache when the flag is off" do
            allow(Config).to receive(:cache_user_auth?).and_return(false)
            2.times { auther.call(rack_env) }
            expect(a_request(:any, %r{api.heroku.com})).to have_been_made.twice
          end
        end
      end
    end

    it "raises Redis::Retry when redis is down" do
      user_info = create_heroku_user
      allow(rack_auth).to receive_messages(provided?: true, basic?: true, credentials: ["", user_info.api_key])

      allow(auther).to receive(:parse_api_key).with(anything).and_raise(Redis::CannotConnectError)
      expect { auther.call(rack_env) }.to raise_error(Redis::Retry::Error)
    end
  end
end
