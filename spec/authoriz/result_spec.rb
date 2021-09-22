require "spec_helper"

module Authoriz
  RSpec.describe Result do
    describe ".can" do
      context "first argument is true" do
        it "runs block" do
          foo = double(:foo)
          expect(foo).to receive(:success)

          Result.can(true) {
            foo.success
          }
        end

        it "runs block and does not run else block" do
          foo = double(:foo)
          expect(foo).to receive(:success)
          expect(foo).not_to receive(:fail)

          Result.can(true) {
            foo.success
          }.else {|reason|
            foo.fail(reason)
          }
        end

        it "does not run else block" do
          foo = double(:foo)
          expect(foo).not_to receive(:fail)

          Result.can(true).else {|reason|
            foo.fail(reason)
          }
        end
      end

      context "first argument is not true" do
        it "does not run block" do
          foo = double(:foo)
          expect(foo).not_to receive(:success)

          Result.can("Unauthorized") {
            foo.success
          }
        end

        it "does not run block and run else block" do
          foo = double(:foo)
          expect(foo).not_to receive(:success)
          expect(foo).to receive(:fail).with("Unauthorized")

          Result.can("Unauthorized") {
            foo.success
          }.else {|reason|
            foo.fail(reason)
          }
        end

        it "runs else block" do
          foo = double(:foo)
          expect(foo).to receive(:fail).with("Unauthorized")

          Result.can("Unauthorized").else {|reason|
            foo.fail(reason)
          }
        end
      end
    end

    describe ".cannot" do
      context "first argument is true" do
        it "does not run block" do
          foo = double(:foo)
          expect(foo).not_to receive(:fail)

          Result.cannot(true) {|reason|
            foo.fail(reason)
          }
        end

        it "does not run block and runs else block" do
          foo = double(:foo)
          expect(foo).not_to receive(:fail)
          expect(foo).to receive(:success)

          Result.cannot(true) {|reason|
            foo.fail(reason)
          }.else {
            foo.success
          }
        end

        it "runs else block" do
          foo = double(:foo)
          expect(foo).to receive(:success)

          Result.cannot(true).else {
            foo.success
          }
        end
      end

      context "first argument is not true" do
        it "runs block" do
          foo = double(:foo)
          expect(foo).to receive(:fail).with("Unauthorized")

          Result.cannot("Unauthorized") {|reason|
            foo.fail(reason)
          }
        end

        it "runs block and does not run else block" do
          foo = double(:foo)
          expect(foo).to receive(:fail).with("Unauthorized")
          expect(foo).not_to receive(:success)

          Result.cannot("Unauthorized") {|reason|
            foo.fail(reason)
          }.else {
            foo.success
          }
        end

        it "does not run else block" do
          foo = double(:foo)
          expect(foo).not_to receive(:success)

          Result.cannot("Unauthorized").else {
            foo.success
          }
        end
      end
    end

    describe "success? and reason" do
      context "constructor's first argument is true" do
        let(:result) { Result.can(true) }
        it "returns true for succes?, nil fo reason" do
          expect(result.success?).to eq true
          expect(result.reason).to eq nil
        end
      end

      context "constructor's first argument is not true" do
        let(:result) { Result.can("Unauthorized") }
        it "returns false for succes?, first argument fo reason" do
          expect(result.success?).to eq false
          expect(result.reason).to eq "Unauthorized"
        end
      end
    end
  end
end
