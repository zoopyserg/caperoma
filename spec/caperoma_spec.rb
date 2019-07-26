# frozen_string_literal: true

require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe Caperoma do
  let!(:project) { create :project, jira_project_id: '123' }

  before { create_capefile('123') }

  describe 'open' do
    context 'query exists' do
      subject { Caperoma.open(['open', 'myproject']) }
  
      context 'project exists' do
        let!(:project) { create :project, jira_project_id: '123', folder_path: '/path/to/myproject' }
  
        let(:content) { /Changing to \/path\/to\/myproject/ }

        it { expect { subject }.to output(content).to_stdout }
      end

      context 'not a single project did not match' do
        let!(:project) { create :project, jira_project_id: '123', folder_path: '/path/to/hisproject' }
  
        let(:content) { /Project not found. Run "caperoma projects" to see them./ }

        it { expect { subject }.to output(content).to_stdout }
      end
  
      context 'more than one project matched' do
        let!(:project1) { create :project, jira_project_id: '123', folder_path: '/path/to/myproject1' }
        let!(:project2) { create :project, jira_project_id: '123', folder_path: '/path/to/myproject2' }
  
        let(:content) { /Found more than one project:/ }

        it { expect { subject }.to output(content).to_stdout }
      end
    end

    context 'query is numeric' do
      subject { Caperoma.open(['open', 1]) }

      context 'project name is numeric exists' do
        let!(:project) { create :project, jira_project_id: '123', folder_path: '/path/to/myproject1' }
  
        let(:content) { /Changing to \/path\/to\/myproject1/ }

        it { expect { subject }.to output(content).to_stdout }
      end
    end

    context 'query does not exist' do
      subject { Caperoma.open(['open']) }

      let!(:content) { /Enter the name/ }

      it { expect { subject }.to output(content).to_stdout }
    end
  end

  describe 'create tasks' do
    context 'title present' do
      let!(:args) { ['bug', '-t', 'awesome bug', '-d', 'some description'] }

      it 'should create' do
        expect do
          Caperoma.create_task(args)
        end.to change {
                 Bug.where(
                   title: 'awesome bug',
                   description: 'some description',
                   project_id: project.id
                 ).count
               }.by(1)
      end
    end

    context 'title present and additional time present' do
      let!(:args) { ['bug', '-t', 'awesome bug', '-a', '5'] }

      it 'should create' do
        expect do
          Caperoma.create_task(args)
        end.to change {
                 Bug.where(
                   title: 'awesome bug',
                   project_id: project.id,
                   additional_time: 5
                 ).count
               }.by(1)
      end
    end

    context 'title present but additional time is invalid' do
      let!(:args) { ['bug', '-t', 'awesome bug', '-a', 'gsov'] }

      subject { Caperoma.create_task(args) }

      it 'should not create' do
        expect do
          subject
        end.to change {
                 Bug.where(
                   title: 'awesome bug',
                   project_id: project.id
                 ).count
               }.by(0)
      end

      it 'should say why it is not starting' do
        expect { subject }.to output(/not_a_number/).to_stdout
      end
    end

    context 'title and pivotal id present but pivotal id is invalid' do
      let!(:args) { ['bug', '-t', 'awesome bug', '-p', 'sdklfvnslfkvs'] }
      let!(:account) { create :account, type: '--pivotal' }

      subject { Caperoma.create_task(args) }

      it 'should create but skip pivotal id' do
        expect do
          subject
        end.to change {
                 Bug.where(
                   title: 'awesome bug',
                   pivotal_id: nil,
                   project_id: project.id
                 ).count
               }.by(1)
      end

      it 'should say why it is skipping' do
        expect { subject }.to output(/Pivotal ID needs to be copied from the task in Pivotal/).to_stdout
      end
    end

    context 'title not present but -p can get the title from pivotal', :unstab_api_calls do
      let!(:args) { ['bug', '-p', '1234567'] }

      let(:response_body) { { 'name' => 'awesome bug', 'description' => 'some description' }.to_json }
      let(:response) { double('Faraday', body: response_body, status: 200) }
      let(:faraday) { double('Faraday', post: response) }

      let!(:account) { create :account, type: '--pivotal' }

      before do
        allow(Faraday).to receive(:new).and_return faraday
        allow(Faraday).to receive(:default_adapter)

        allow(faraday).to receive(:post).and_return response
        allow(faraday).to receive(:get).and_return response
        allow(faraday).to receive(:put).and_return response
      end

      it 'should create' do
        expect do
          Caperoma.create_task(args)
        end.to change {
                 Bug.where(
                   title: 'awesome bug',
                   description: 'some description',
                   project_id: project.id
                 ).count
               }.by(1)
      end
    end

    context 'title not present, -p present, but pivotal Account is not set up' do
      let!(:args) { ['bug', '-p', '1234567'] }

      let(:response_body) { { 'name' => 'awesome bug', 'description' => 'some description' }.to_json }
      let(:response) { double('Faraday', body: response_body, status: 200) }
      let(:faraday) { double('Faraday', post: response) }

      before do
        allow(Faraday).to receive(:new).and_return faraday
        allow(Faraday).to receive(:default_adapter)

        allow(faraday).to receive(:post).and_return response
        allow(faraday).to receive(:get).and_return response
        allow(faraday).to receive(:put).and_return response
      end

      subject { Caperoma.create_task(args) }

      it 'should not create' do
        expect do
          subject
        end.to change {
                 Bug.where(
                   title: 'awesome bug',
                   description: 'some description',
                   project_id: project.id
                 ).count
               }.by(0)
      end

      it 'should say it could not get access' do
        expect { subject }.to output(/Please set up Pivotal account/).to_stdout
      end
    end

    context 'title not present, -p present, but pivotal gave an error', :unstab_api_calls do
      let!(:args) { ['bug', '-p', '1234567'] }

      let(:response_body) { { 'name' => 'awesome bug', 'description' => 'some description' }.to_json }
      let(:response) { double('Faraday', body: response_body, status: 401) }
      let(:faraday) { double('Faraday', post: response) }

      let!(:account) { create :account, type: '--pivotal' }

      before do
        allow(Faraday).to receive(:new).and_return faraday
        allow(Faraday).to receive(:default_adapter)

        allow(faraday).to receive(:post).and_return response
        allow(faraday).to receive(:get).and_return response
        allow(faraday).to receive(:put).and_return response
      end

      subject { Caperoma.create_task(args) }

      it 'should not create' do
        expect do
        end.to change {
                 Bug.where(
                   title: 'awesome bug',
                   description: 'some description',
                   project_id: project.id
                 ).count
               }.by(0)
      end

      it 'should say it could not get access' do
        expect { subject }.to output(/No access/).to_stdout
      end
    end

    context 'title not present but -p can get the title from pivotal, but pivotal_id is set in #1234567 format (not just numbers)', :unstab_api_calls do
      let!(:args) { ['bug', '-p', '#1234567'] }

      let(:response_body) { { 'name' => 'awesome bug', 'description' => 'some description' }.to_json }

      let(:response) { double('Faraday', body: response_body, status: 200) }
      let(:faraday) { double('Faraday', post: response) }

      let!(:account) { create :account, type: '--pivotal' }

      before do
        allow(Faraday).to receive(:new).and_return faraday
        allow(Faraday).to receive(:default_adapter)

        allow(faraday).to receive(:post).and_return response
        allow(faraday).to receive(:get).and_return response
        allow(faraday).to receive(:put).and_return response
      end

      it 'should create the same way as it does without #' do
        expect do
          Caperoma.create_task(args)
        end.to change {
                 Bug.where(
                   title: 'awesome bug',
                   description: 'some description',
                   project_id: project.id
                 ).count
               }.by(1)
      end
    end
  end

  describe 'get_jira_project_ids' do
    subject { Caperoma.get_jira_project_ids }

    context 'Account does not exist' do
      it { expect { subject }.to output(/set up Jira/).to_stdout }
    end

    context 'Account exists' do
      let!(:account) { create :account, type: '--jira' }

      before { remove_capefile }

      context 'capefile does not exist' do
        it { expect { subject }.to output(/Capefile not found/).to_stdout }
      end

      context 'capefile without jira_url' do
        before { File.write 'Capefile.test', 'pivotal_id: 12345' }

        it { expect { subject }.to output(/Please put at least jira url into your Capefile/).to_stdout }
      end

      context 'invalid capefile' do
        before { File.write 'Capefile.test', '#(*$#>#)@*@' }

        it { expect { subject }.to output(/Can not parse/).to_stdout }
      end

      context 'capefile exists' do
        let(:response_body) { [{ 'name' => 'Project 1', 'id' => '34' }, { 'name' => 'Project 2', 'id' => '55' }].to_json }
        let(:response) { double('Faraday', body: response_body, status: status, reason_phrase: reason_phrase) }
        let(:faraday) { double('Faraday', post: response) }

        let(:status) { 200 }
        let(:reason_phrase) { 'OK' }

        before do
          create_capefile # move out
          allow(Faraday).to receive(:new).and_return faraday
          allow(Faraday).to receive(:default_adapter)
        end

        context 'no connection' do
          before do
            allow(faraday).to receive(:post).and_raise Faraday::ConnectionFailed, [404]
            allow(faraday).to receive(:get).and_raise Faraday::ConnectionFailed, [404]
            allow(faraday).to receive(:put).and_raise Faraday::ConnectionFailed, [404]
          end

          it { expect { subject }.to output(/Connection failed/).to_stdout }
        end

        describe 'statuses' do
          before do
            allow(faraday).to receive(:post).and_return response
            allow(faraday).to receive(:get).and_return response
            allow(faraday).to receive(:put).and_return response
          end

          context 'everything is ok' do
            let(:status) { 200 }
            let(:reason_phrase) { 'OK' }

            it { expect { subject }.to output(/Name: Project 1, jira_project_id: 34/).to_stdout }
            it { expect { subject }.to output(/Name: Project 2, jira_project_id: 55/).to_stdout }
          end

          context 'unauthorized 401' do
            let(:status) { 401 }
            let(:reason_phrase) { 'not authorized' }

            it { expect { subject }.to output(/No access to Jira/).to_stdout }
          end

          context 'unauthorized 403' do
            let(:status) { 403 }
            let(:reason_phrase) { 'not authorized' }

            it { expect { subject }.to output(/No access to Jira/).to_stdout }
          end

          context 'not found 404' do
            let(:status) { 404 }
            let(:reason_phrase) { 'not found' }

            it { expect { subject }.to output(/not found/).to_stdout }
          end

          context 'other error' do
            let(:status) { 500 }
            let(:reason_phrase) { 'server error' }

            it { expect { subject }.to output(/Could not/).to_stdout }
            it { expect { subject }.to output(/500/).to_stdout }
            it { expect { subject }.to output(/server error/).to_stdout }
          end
        end
      end
    end
  end

  describe 'get_jira_issue_type_ids' do
    subject { Caperoma.get_jira_issue_type_ids }

    context 'Account does not exist' do
      it { expect { subject }.to output(/set up Jira/).to_stdout }
    end

    context 'Account exists' do
      let!(:account) { create :account, type: '--jira' }

      before { remove_capefile }

      context 'capefile does not exist' do
        it { expect { subject }.to output(/Capefile not found/).to_stdout }
      end

      context 'capefile without jira_url' do
        before { File.write 'Capefile.test', 'pivotal_id: 12345' }

        it { expect { subject }.to output(/Please put at least jira url into your Capefile/).to_stdout }
      end

      context 'invalid capefile' do
        before { File.write 'Capefile.test', '#(*$#>#)@*@' }

        it { expect { subject }.to output(/Can not parse/).to_stdout }
      end

      context 'capefile exists' do
        let(:response_body) { [{ 'name' => 'Type 1', 'id' => '34' }, { 'name' => 'Type 2', 'id' => '55' }].to_json }
        let(:response) { double('Faraday', body: response_body, status: status, reason_phrase: reason_phrase) }
        let(:faraday) { double('Faraday', post: response) }

        let(:status) { 200 }
        let(:reason_phrase) { 'OK' }

        before do
          create_capefile # move out
          allow(Faraday).to receive(:new).and_return faraday
          allow(Faraday).to receive(:default_adapter)
        end

        context 'no connection' do
          before do
            allow(faraday).to receive(:post).and_raise Faraday::ConnectionFailed, [404]
            allow(faraday).to receive(:get).and_raise Faraday::ConnectionFailed, [404]
            allow(faraday).to receive(:put).and_raise Faraday::ConnectionFailed, [404]
          end

          it { expect { subject }.to output(/Connection failed/).to_stdout }
        end

        describe 'statuses' do
          before do
            allow(faraday).to receive(:post).and_return response
            allow(faraday).to receive(:get).and_return response
            allow(faraday).to receive(:put).and_return response
          end

          context 'everything is ok' do
            let(:status) { 200 }
            let(:reason_phrase) { 'OK' }

            it { expect { subject }.to output(/Name: Type 1, ID: 34/).to_stdout }
            it { expect { subject }.to output(/Name: Type 2, ID: 55/).to_stdout }
          end

          context 'unauthorized 401' do
            let(:status) { 401 }
            let(:reason_phrase) { 'not authorized' }

            it { expect { subject }.to output(/No access to Jira/).to_stdout }
          end

          context 'unauthorized 403' do
            let(:status) { 403 }
            let(:reason_phrase) { 'not authorized' }

            it { expect { subject }.to output(/No access to Jira/).to_stdout }
          end

          context 'not found 404' do
            let(:status) { 404 }
            let(:reason_phrase) { 'not found' }

            it { expect { subject }.to output(/not found/).to_stdout }
          end

          context 'other error' do
            let(:status) { 500 }
            let(:reason_phrase) { 'server error' }

            it { expect { subject }.to output(/Could not/).to_stdout }
            it { expect { subject }.to output(/500/).to_stdout }
            it { expect { subject }.to output(/server error/).to_stdout }
          end
        end
      end
    end
  end

  describe 'get_jira_transition_ids' do
    subject { Caperoma.get_jira_transition_ids }

    context 'Account does not exist' do
      it { expect { subject }.to output(/set up Jira/).to_stdout }
    end

    context 'Account exists' do
      let!(:account) { create :account, type: '--jira' }

      before { remove_capefile }

      context 'capefile does not exist' do
        it { expect { subject }.to output(/Capefile not found/).to_stdout }
      end

      context 'capefile without jira_url' do
        before { File.write 'Capefile.test', 'pivotal_id: 12345' }

        it { expect { subject }.to output(/Please put jira_url into your Capefile/).to_stdout }
      end

      context 'invalid capefile' do
        before { File.write 'Capefile.test', '#(*$#>#)@*@' }

        it { expect { subject }.to output(/Can not parse/).to_stdout }
      end

      context 'capefile exists' do
        let(:response_body) { { 'issues' => issues, 'transitions' => [{ 'name' => 'Transition 1', 'id' => '34' }, { 'name' => 'Transition 2', 'id' => '55' }] }.to_json }
        let(:response) { double('Faraday', body: response_body, status: status, reason_phrase: reason_phrase) }
        let(:faraday) { double('Faraday', post: response) }

        let(:status) { 200 }
        let(:reason_phrase) { 'OK' }

        before do
          allow(Faraday).to receive(:new).and_return faraday
          allow(Faraday).to receive(:default_adapter)
        end

        before { create_capefile }

        before do
          allow(faraday).to receive(:post).and_return response
          allow(faraday).to receive(:get).and_return response
          allow(faraday).to receive(:put).and_return response
        end

        context 'issues do not exist' do
          let(:issues) { [] }

          it { expect { subject }.to output(/Please create at least one issue in this project manually in the browser/).to_stdout }
        end

        context 'issues exist' do
          let(:issues) { [{ 'key' => 'RUC-123' }] }

          context 'no connection' do
            before do
              allow(faraday).to receive(:post).and_raise Faraday::ConnectionFailed, [404]
              allow(faraday).to receive(:get).and_raise Faraday::ConnectionFailed, [404]
              allow(faraday).to receive(:put).and_raise Faraday::ConnectionFailed, [404]
            end

            it { expect { subject }.to output(/Connection failed/).to_stdout }
          end

          describe 'statuses' do
            before do
              allow(faraday).to receive(:post).and_return response
              allow(faraday).to receive(:get).and_return response
              allow(faraday).to receive(:put).and_return response
            end

            context 'everything is ok' do
              let(:status) { 200 }
              let(:reason_phrase) { 'OK' }

              it { expect { subject }.to output(/Name: Transition 1, ID: 34/).to_stdout }
              it { expect { subject }.to output(/Name: Transition 2, ID: 55/).to_stdout }
            end

            context 'unauthorized 401' do
              let(:status) { 401 }
              let(:reason_phrase) { 'not authorized' }

              it { expect { subject }.to output(/No access to Jira/).to_stdout }
            end

            context 'unauthorized 403' do
              let(:status) { 403 }
              let(:reason_phrase) { 'not authorized' }

              it { expect { subject }.to output(/No access to Jira/).to_stdout }
            end

            context 'not found 404' do
              let(:status) { 404 }
              let(:reason_phrase) { 'not found' }

              it { expect { subject }.to output(/not found/).to_stdout }
            end

            context 'other error' do
              let(:status) { 500 }
              let(:reason_phrase) { 'server error' }

              it { expect { subject }.to output(/Could not/).to_stdout }
              it { expect { subject }.to output(/500/).to_stdout }
              it { expect { subject }.to output(/server error/).to_stdout }
            end
          end
        end
      end
    end
  end
end
