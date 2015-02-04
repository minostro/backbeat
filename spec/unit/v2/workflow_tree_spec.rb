require "spec_helper"
require "v2/helpers/colorize"

describe V2::WorkflowTree, v2: true do
  let(:user) { FactoryGirl.create(:v2_user) }
  let(:workflow) { FactoryGirl.create(:v2_workflow, user: user) }

  def add_node(parent, name)
    FactoryGirl.create(
      :v2_node,
      parent: parent,
      workflow_id: workflow.id,
      name: name,
      user: user
    )
  end

  context "to_hash" do
    it "returns the tree as a hash with no children" do
      expect(V2::WorkflowTree.to_hash(workflow)).to eq({
        id: workflow.uuid,
        current_server_status: nil,
        current_client_status: nil,
        name: workflow.name,
        children: []
      })
    end

    it "returns the tree as a hash with children" do
      add_node(workflow, "Workflow child")

      expect(V2::WorkflowTree.to_hash(workflow)).to eq({
        id: workflow.uuid,
        current_server_status: nil,
        current_client_status: nil,
        name: workflow.name,
        children: [
          {
            id: workflow.children.first.uuid,
            current_server_status: "pending",
            current_client_status: "ready",
            name: "Workflow child",
            children: []
          }
        ]
      })
    end

    it "returns the tree as a hash with nested children" do
      add_node(workflow, "Workflow child")
      add_node(workflow, "Another Workflow child")
      add_node(workflow.children.first, "Nested child")

      expect(V2::WorkflowTree.to_hash(workflow)).to eq({
        id: workflow.uuid,
        current_server_status: nil,
        current_client_status: nil,
        name: workflow.name,
        children: [
          {
            id: workflow.children.first.uuid,
            current_server_status: "pending",
            current_client_status: "ready",
            name: "Workflow child",
            children: [
              {
                id: workflow.children.first.children.first.uuid,
                current_server_status: "pending",
                current_client_status: "ready",
                name: "Nested child",
                children: []
              }
            ]
          },
          {
            id: workflow.children.last.uuid,
            current_server_status: "pending",
            current_client_status: "ready",
            name: "Another Workflow child",
            children: []
          }
        ]
      })
    end
  end

  include Colorize

  context "to_string" do
    it "returns the tree as a string with no children" do
      expect(V2::WorkflowTree.to_string(workflow)).to eq(
        "\n#{workflow.uuid}#{cyan("|--")}#{workflow.name}"
      )
    end

    it "returns the tree as a string with children" do
      child = add_node(workflow, "Workflow child")
      child.update_attributes(current_server_status: :errored)

      expect(V2::WorkflowTree.to_string(workflow)).to eq(
        "\n#{workflow.uuid}#{cyan("|--")}#{workflow.name}"\
        "\n#{child.uuid}#{cyan("   |--")}#{red("#{child.name} - server: #{child.current_server_status}, client: #{child.current_client_status}")}"
      )
    end

    it "returns the tree as a hash with nested children" do
      child_1 = add_node(workflow, "Workflow child")
      child_2 = add_node(workflow, "Another Workflow child")
      child_3 = add_node(workflow.children.first, "Nested child")

      child_1.update_attributes(current_server_status: :processing_children)
      child_2.update_attributes(current_server_status: :complete)
      child_3.update_attributes(current_server_status: :sent_to_client)

      expect(V2::WorkflowTree.to_string(workflow)).to eq(
        "\n#{workflow.uuid}#{cyan("|--")}#{workflow.name}"\
        "\n#{child_1.uuid}#{cyan("   |--")}#{yellow("#{child_1.name} - server: #{child_1.current_server_status}, client: #{child_1.current_client_status}")}"\
        "\n#{child_3.uuid}#{cyan("      |--")}#{yellow("#{child_3.name} - server: #{child_3.current_server_status}, client: #{child_3.current_client_status}")}"\
        "\n#{child_2.uuid}#{cyan("   |--")}#{green("#{child_2.name} - server: #{child_2.current_server_status}, client: #{child_2.current_client_status}")}"
      )
    end
  end
end