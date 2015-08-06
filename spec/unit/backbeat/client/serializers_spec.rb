require "spec_helper"

describe "Serializers" do

  let(:user) { FactoryGirl.create(:user) }
  let(:workflow) { FactoryGirl.create(:workflow_with_node, user: user) }
  let(:node) { workflow.children.first }

  context "NodeSerializer" do
    it "serializes a node" do
      expect(Backbeat::Client::NodeSerializer.call(node)).to eq(
        {
          id: node.id,
          mode: node.mode,
          name: node.name,
          workflow_id: node.workflow_id,
          parent_id: node.parent_id,
          user_id: node.user_id,
          client_data: node.client_data,
          metadata: node.client_metadata,
          subject: node.subject,
          decider: node.decider,
          workflow_name: node.workflow.name,
          current_server_status: node.current_server_status,
          current_client_status: node.current_client_status
        }
      )
    end
  end

  context "NotificationSerializer" do
    it "serializers a notification" do
      expect(Backbeat::Client::NotificationSerializer.call(node, "A message")).to eq(
        {
          notification: {
            type: "Backbeat::Node",
            id: node.id,
            name: node.name,
            subject: node.subject,
            message: "A message"
          },
          error: nil
        }
      )
    end
  end

  context "ErrorSerializer" do
    it "formats the hash for StandardErrors" do
      error = StandardError.new('some_error')
      expect(Backbeat::Client::ErrorSerializer.call(error)).to eq({
        error_klass: error.class.to_s,
        message: error.message
      })
    end

    it "adds backtrace if it exists" do
      begin
        raise StandardError.new('some_error')
      rescue => error
        expect(Backbeat::Client::ErrorSerializer.call(error)).to eq({
          error_klass: error.class.to_s,
          message: error.message,
          backtrace: error.backtrace
        })
      end
    end

    it "formats the hash for strings" do
      error = "blah"
      expect(Backbeat::Client::ErrorSerializer.call(error)).to eq({
        error_klass: error.class.to_s,
        message: error
      })
    end

    it "doesn't format for other other class types" do
      error = 1
      expect(Backbeat::Client::ErrorSerializer.call(error)).to eq(1)
    end
  end
end