module SourceControl

  class Git < AbstractAdapter

    attr_accessor :repository

    def initialize(options)
      options = options.dup
      @path = options.delete(:path) || "."
      @error_log = options.delete(:error_log)
      @interactive = options.delete(:interactive)
      @repository = options.delete(:repository)
      @branch = options.delete(:branch)
      raise "don't know how to handle '#{options.keys.first}'" if options.length > 0
    end

    def checkout(revision = nil, stdout = $stdout)
      raise 'Repository location is not specified' unless @repository

      raise "#{path} is not empty, cannot clone a project into it" unless (Dir.entries(path) - ['.', '..']).empty?
      FileUtils.rm_rf(path)

      # need to read from command output, because otherwise tests break
      git('clone', [@repository, path], :execute_in_project_directory => false) do |io|
        begin
          while line = io.gets
            stdout.puts line
          end
        rescue EOFError
        end
      end

      if @branch
        git('branch', ['--track', @branch, "origin/#@branch"])
        git('checkout', [@branch])
      end
      git("reset", ['--hard', revision.number]) if revision
    end

    # TODO implement clean_checkout as "git clean -d" - much faster
    def clean_checkout(revision = nil, stdout = $stdout)
      super(revision, stdout)
    end

    def latest_revision
      load_new_changesets_from_origin
      git_output = git('log', ['-1', '--pretty=raw', "origin/#{current_branch}"])
      Git::LogParser.new.parse(git_output).first
    end

    def update(revision = nil)
      if revision
        git("reset", ["--hard", revision.number])
      else
        git("reset", ["--hard"])
      end
    end

    def up_to_date?(reasons = [])
      _new_revisions = new_revisions
      if _new_revisions.empty?
        return true
      else
        reasons << _new_revisions
        return false
      end
    end

    def creates_ordered_build_labels?() false end

    def new_revisions
      load_new_changesets_from_origin
      git_output = git('log', ['--pretty=raw', "HEAD..origin/#{current_branch}"])
      Git::LogParser.new.parse(git_output)
    end

    def current_branch
      git('branch') do |io|
        branch = io.readlines.grep(/^\* .*$/).first[2..-1].strip
        return branch
      end
    end

    protected

    def load_new_changesets_from_origin
      git("fetch", ["origin"])
    end

    def git(operation, arguments = [], options = {}, &block)
      command = ["git", operation] + arguments.compact
# TODO: figure out how to handle the same thing with git
#      command << "--non-interactive" unless @interactive

      execute_in_local_copy(command, options, &block)
    end

  end

end