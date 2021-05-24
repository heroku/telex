module Middleware
  RSpec.describe ProducerAuthenticator do
    let(:app) { double(:app) }
    let(:rack_env) { double(:rack_env) }
    let(:rack_auth) { double(:auth) }

    let(:key1) { "passw0rd" }
    let(:key2) { "mr. fluffy" }
    let(:key3) { "super-secret" }

    let(:producer1) { Fabricate(:producer, api_key: key1) }
    let(:producer2) { Fabricate(:producer, api_key: key2) }
    let(:producer3) { Fabricate(:producer, api_key: key3) }

    let(:auther) { ProducerAuthenticator.new(app) }

    describe "#call" do
      before do
        expect(Rack::Auth::Basic::Request).to receive(:new)
          .with(rack_env).and_return(rack_auth)
      end

      it "raises Unauthorized if no credentials are provided" do
        allow(rack_auth).to receive_messages(provided?: false, basic?: true, credentials: nil)
        expect { auther.call(rack_env) }.to raise_error(Pliny::Errors::Unauthorized)
      end

      it "raises Unauthorized when incorrect credentials are provided" do
        allow(rack_auth).to receive_messages(provided?: true, basic?: true, credentials: [producer1.id, key2])
        expect { auther.call(rack_env) }.to raise_error(Pliny::Errors::Unauthorized)
      end

      it "raises Unauthorized when credentials of a non-existent producer are provided" do
        allow(rack_auth).to receive_messages(provided?: true, basic?: true, credentials: [SecureRandom.uuid, "api_key123"])
        expect { auther.call(rack_env) }.to raise_error(Pliny::Errors::Unauthorized)
      end

      it "raises Unauthorized for auth other than basic auth" do
        allow(rack_auth).to receive_messages(provided?: false, basic?: false, credentials: [producer1.id, key1])
        expect { auther.call(rack_env) }.to raise_error(Pliny::Errors::Unauthorized)
      end

      describe "with correct credentials" do
        before do
          expect(app).to receive(:call).with(rack_env)
        end

        it "finds the right producer with the correct credentials" do
          allow(rack_auth).to receive_messages(provided?: true, basic?: true, credentials: [producer1.id, key1])
          auther.call(rack_env)
          expect(Pliny::RequestStore.store[:current_producer].id).to eq(producer1.id)
        end

        it "finds the right producer even when two producers have same api_key" do
          allow(rack_auth).to receive_messages(provided?: true, basic?: true, credentials: [producer1.id, key1])
          producer2.update(api_key: key1)
          auther.call(rack_env)
          expect(Pliny::RequestStore.store[:current_producer].id).to eq(producer1.id)
        end
      end
    end
  end
end
