describe "common-tags module" do
  before(:all) do
    mod_path = File.expand_path("../..", __dir__)
    terraspace.build_test_harness(
      name: "common-tags-harness",
      modules: {
        "common-tags": mod_path
      },
      tfvars: {
        "common-tags": "spec/fixtures/tfvars/test.tfvars"
      },
    )
    terraspace.up("common-tags")
  end
  after(:all) do
    terraspace.down("common-tags")
  end

  it "should return a list of common resources tags" do
    expect(terraspace.output("common-tags", "tags")).to eq({
      "Environment" => "test-environment",
      "ManagedBy" => "terraform",
      "Stack" => "test-stack",
      "Project" => "test-project",
      "Organisation" => "NearForm"
    })
  end
end
