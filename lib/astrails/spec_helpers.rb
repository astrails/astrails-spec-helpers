def default_action_method(action)
  case action
  when :index, :new, :show, :edit
    :get
  when :create
    :post
  when :update
    :put
  when :destroy
    :delete
  else
    raise "unknown action #{action.inspect}"
  end
end

module Astrails
  module SpecHelpers

    module Common
      module ExampleMethods
        def stub_user(stubs = {})
          returning(stub_model(User, {:save => true}.merge(stubs))) do |user|
            user.reset_persistence_token unless user.persistence_token
            user.reset_perishable_token unless user.perishable_token
          end
        end

        def prepare_model(model)
          name = model.to_s.downcase
          instance_variable_get("@#{model}") || instance_variable_set("@#{name}", send("stub_#{name}".to_sym))
        end

      end
      module ExampleGroupMethods
        def prepare_model(model)
          before(:each) {prepare_model(model)}
        end
      end
    end

    module Controller
      def self.included(base)
        base.extend         Common::ExampleGroupMethods
        base.extend         ExampleGroupMethods
        base.send :include, Common::ExampleMethods
        base.send :include, ExampleMethods
      end

      module ExampleMethods

        def stub_finds(klass, obj)
          klass.stub!(:find)      .with(obj)                  .and_return(obj)
          klass.stub!(:find)      .with(obj.id)               .and_return(obj)
          klass.stub!(:find)      .with(obj.id, anything)     .and_return(obj)
          klass.stub!(:find)      .with(obj.id.to_s)          .and_return(obj)
          klass.stub!(:find)      .with(obj.id.to_s, anything).and_return(obj)
          klass.stub!(:find_by_id).with(obj.id)               .and_return(obj)
          klass.stub!(:find_by_id).with(obj.id, anything)     .and_return(obj)
          klass.stub!(:find_by_id).with(obj.id.to_s)          .and_return(obj)
          klass.stub!(:find_by_id).with(obj.id.to_s, anything).and_return(obj)
          obj
        end

        def stub_user_and_find(stubs = {})
          stub_finds(User, stub_user(stubs))
        end

        def stub_current_user(stubs = {}, user = stub_user_and_find(stubs))
          return if @current_user
          UserSession.create(@current_user = user)
          user
        end

        def stubs_for_new(model, valid = true)
          var = prepare_model(model)
          model.stub!(:new).and_return(var)
        end

        def stubs_for_create(model, valid = true)
          var = prepare_model(model)
          model.stub!(:new).and_return(var)
          var.stub!(:save).and_return(valid)
        end

        def stubs_for_update(model, valid = true)
          var = prepare_model(model)
          var.stub!(:update_attributes).and_return(valid)
        end

        def stubs_for_destroy(model, valid = true)
          var = prepare_model(model)
          var.stub!(:destroy).and_return(valid)
        end

        def stubs_for_index(model)
          stub_find_all model.to_s.classify.constantize, :find_method => :paginate
        end

        def shared_request
          params[:id] ||= "__id__" if [:edit, :update, :destroy].include?(@action)
          send(default_action_method(@action), @action, params)
        end

        def set_action(action)
          @action = action
        end

      end

      module ExampleGroupMethods

        def stub_current_user(stubs = {})
          before(:each) {stub_current_user(stubs)}
        end

        def with_current_user
          stub_current_user
          before(:each) do
            @user = @current_user
            stub_finds(User, @user)
            params[:id] = @user.id
          end
        end

        def with_other_user
          stub_current_user
          before(:each) do
            @user = stub_user
            stub_finds(User, @user)
            params[:id] = @user.id
          end
        end


        def stubs_for_new(model, valid = true)
          before(:each) do
            stubs_for_new(model, valid)
          end
        end

        def stubs_for_create(model, valid = true)
          before(:each) do
            stubs_for_create(model, valid)
          end
        end

        def stubs_for_update(model, valid = true)
          before(:each) {stubs_for_update(model, valid)}
        end

        def stubs_for_destroy(model, valid = true)
          before(:each) {stubs_for_destroy(model, valid)}
        end

        def it_should_paginate_and_assign(name)
          it_should_find name, :only_method => true, :find_method => :paginate
          it_should_assign name
        end

        def stubs_for_index(model)
          before(:each) do
            stubs_for_index(model)
          end
        end

        def set_action(action)
          before(:each) {set_action action}
        end

        def describe_action(action, &block)
          describe "#{default_action_method(action).to_s.upcase} #{action}" do
            set_action action
            class_eval &block
          end
        end

        def add_params(_params)
          before(:each) { params.merge!(_params) }
        end

        def it_should_match(collection, key, rexp)
          it "#{collection}[:#{key}] should match #{rexp.inspect}" do
            flash.stub!(:sweep) if collection == :flash
            eval_request
            self.send(collection)[key].should =~ rexp
          end
        end

        def it_should_set_errors_on(model)
          it "should set errors on #{model}" do
            eval_request
            assigns[model].errors.should_not be_blank
          end
        end

        def it_should_not_set_errors_on(model)
          it "should set errors on #{model}" do
            eval_request
            assigns[model].errors.should be_blank
          end
        end
      end
    end
    module View
      def self.included(base)
        base.extend         Common::ExampleGroupMethods
        base.extend         ExampleGroupMethods
        base.send :include, Common::ExampleMethods
        base.send :include, ExampleMethods
      end
      module ExampleMethods
      end
      module ExampleGroupMethods
      end
    end
  end
end
Spec::Rails::Example::ControllerExampleGroup.send :include, Astrails::SpecHelpers::Controller
Spec::Rails::Example::ViewExampleGroup.send :include, Astrails::SpecHelpers::View
