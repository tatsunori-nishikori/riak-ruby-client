require 'spec_helper'

describe Riak::Client do

  before do
    @client = Riak::Client.new
    @backend = double("Backend")
    allow(@client).to receive(:backend).and_yield(@backend)
    allow(@client).to receive(:http).and_yield(@backend)
    @bucket = Riak::Bucket.new(@client, "foo")

    @events = []
    @notifier = ActiveSupport::Notifications.notifier
    @notifier.subscribe { |*args| (@events ||= []) << event(*args) }
  end

  describe "instrumentation", instrumentation: true do

    it "should notify on the 'buckets' operation" do
      expect(@backend).to receive(:list_buckets).and_return(%w{test test2})
      test_client_event(@client, 'riak.list_buckets') do
        @client.buckets
      end
    end

    it "should notify on the 'list_buckets' operation" do
      expect(@backend).to receive(:list_buckets).and_return(%w{test test2})
      test_client_event(@client, 'riak.list_buckets') do
        @client.list_buckets
      end
    end

    it "should notify on the 'list_keys' operation" do
      expect(@backend).to receive(:list_keys).and_return(%w{test test2})
      test_client_event(@client, 'riak.list_keys') do
        @client.list_keys(@bucket)
      end
    end

    it "should notify on the 'get_bucket_props' operation" do
      expect(@backend).to receive(:get_bucket_props).and_return({})
      test_client_event(@client, 'riak.get_bucket_props') do
        @client.get_bucket_props(@bucket)
      end
    end

    it "should notify on the 'set_bucket_props' operation" do
      expect(@backend).to receive(:set_bucket_props).and_return({})
      test_client_event(@client, 'riak.set_bucket_props') do
        @client.set_bucket_props(@bucket, {})
      end
    end

    it "should notify on the 'clear_bucket_props' operation" do
      expect(@backend).to receive(:reset_bucket_props).and_return({})
      test_client_event(@client, 'riak.clear_bucket_props') do
        @client.clear_bucket_props(@bucket)
      end
    end

    it "should notify on the 'get_index' operation" do
      expect(@backend).to receive(:get_index).and_return({})
      test_client_event(@client, 'riak.get_index') do
        @client.get_index(@bucket, 'index', 'query', {})
      end
    end

    it "should notify on the 'get_object' operation" do
      expect(@backend).to receive(:fetch_object).and_return(nil)
      test_client_event(@client, 'riak.get_object') do
        @client.get_object(@bucket, 'bar')
      end
    end

    it "should notify on the 'store_object' operation" do
      expect(@backend).to receive(:store_object).and_return(nil)
      test_client_event(@client, 'riak.store_object') do
        @client.store_object(Object.new)
      end
    end

    it "should notify on the 'reload_object' operation" do
      expect(@backend).to receive(:reload_object).and_return(nil)
      test_client_event(@client, 'riak.reload_object') do
        @client.reload_object(Object.new)
      end
    end

    it "should notify on the 'delete_object' operation" do
      expect(@backend).to receive(:delete_object).and_return(nil)
      test_client_event(@client, 'riak.delete_object') do
        @client.delete_object(@bucket, 'bar')
      end
    end

    it "should notify on the 'mapred' operation" do
      @mapred = Riak::MapReduce.new(@client).add('test').map("function(){}").map("function(){}")
      expect(@backend).to receive(:mapred).and_return(nil)
      test_client_event(@client, 'riak.map_reduce') do
        @client.mapred(@mapred)
      end
    end

    it "should notify on the 'ping' operation" do
      expect(@backend).to receive(:ping).and_return(nil)
      test_client_event(@client, 'riak.ping') do
        @client.ping
      end
    end
  end
end

def test_client_event(client, event_name, &block)
  block.call
  expect(@events.size).to eql(1)
  event = @events.first
  expect(event.name).to eql(event_name)
  expect(event.payload[:client_id]).to eql(client.client_id)
end

# name, start, finish, id, payload
def event(*args)
  ActiveSupport::Notifications::Event.new(*args)
end
