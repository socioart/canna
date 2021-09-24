# Canny

Canny は認可ロジックの記述を支援するライブラリです。
下記の特徴があります。

* No DSL: 認可ロジックは DSL でなく、メソッドとして記述します。これによりクラスごとのコードの分離が可能になり、テストやメタプログラミングも容易になります。
* Support arguments: 認可メソッドには任意の数の引数、キーワード引数を渡すことができます。「親オブジェクト」によって認可するか分岐することができます。
* Reasonable: 不認可時に理由を表現する任意のオブジェクトを返すことができます。
* Rails integration: Ruby on Rails 用のヘルパーメソッドを同梱しています。

## Installation

Add this line to your application's Gemfile:

```ruby
gem "canny"
```

If you use Ruby on Rails:

```ruby
gem "canny", require: "canny/rails"
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install canny

## Usage

```ruby
class Project < ApplicationRecord
  belongs_to :owner

  # `authorize_to_[アクション名]` メソッドを定義します。
  # アクション名は任意の文字列ですが Rails なら ActionController に定義したアクション名にすると便利です。
  # このメソッドは認可時には `true` を返す必要があります。
  # 不認可時には (`true` 以外の) 不認可の理由を表現するオブジェクトを返します (特に理由の情報が必要なければ false や nil でも構いません)。
  def self.authorize_to_create(current_user)
    current_user.admin? || "Administrator only can create Project"
  end
end

class Document < ApplicationRecord
  belongs_to :project

  # 認可メソッドは任意の引数を取ることができます。
  def self.authorize_to_index(current_user, project: project)
    (project.owner == current_user) || "You can only index documents in own project"
  end
end

# Authorizer のコンストラクタの引数は任意です。引数は認可メソッド呼び出し時の引数に必ず追加されます。
authorizer = Canny::Authorizer.new(current_user)

# can?, cannot? メソッドは単純に `true` (認可) or `false` (不認可) を返します。
authorizer.can?(:index, Document, project: project) # => 認可時は `true`、不認可時は `false`
authorizer.cannot?(:index, Document, project: project) # => 認可時は `false`、不認可時は `true`

# can, cannot メソッドはブロックを取ることができます。このブロックはそれぞれ認可・不認可時にのみ実行されます。
# cannot のブロックには不認可の理由が引数で渡されます。
authorizer.can(:create, Project) {
  puts "authorized" # 認可時のみ実行
}
authorizer.cannot(:create, Project) {|reason| # 不認可の理由が引数で渡される
  puts "unauthorized #{reason}" # 不認可時のみ実行
}

# このブロックに続けて `else` メソッドを呼ぶことで、逆の結果だった場合の処理を書くことができます
authorizer.can(:create, Project) {
  puts "authorized" # 認可時のみ実行
}.else {|reason|
  puts "unauthorized #{reason}" # 不認可時のみ実行
}

# ブロックの返り値が得たい場合は続けて `value` メソッドを呼びます。
# (else を使わない場合でも使えます。ブロックが実行されない場合は `nil` が返ります。)
message = authorizer.can(:create, Project) {
  "authorized"
}.else {|reason|
  "unauthorized #{reason}"
}.value
puts message # 認可時は "authorized" 不認可時は "unauthorized: #{reason}"

# ブロックを使わない場合は can の返り値の `authorized?` メソッドで認可の可否、`reason` メソッドで不認可の理由が得られます。
result = authorizer.can(:create, Project)

if result.authorized? # 認可時は `true`、不認可時は `false`
  puts "authorized"
else
  puts "unauthorized #{result.reason}"
end
```

## Ruby on Rails Integration

```ruby
class DocumentController <_ApplicationController
  before_action :find_project


  def index
    # 認可時は何もしません。
    # 不認可時は Canny::Unauthorized を raise するので、通常は ApplicationController#rescue_from でこのときの処理を記述してください。
    # 下記の例では Document.authorize_to_index(current_user, project: project) が呼ばれます。
    authorize! :index, Document, project: @project
    # ...
  end

  def show
    # 下記の例では @document.authorize_to_show(current_user) が呼ばれます。
    authorize! :show, @document
    # ...
  end

  private
  # デフォルトで current_user を引数にした Authorizer が使われます。変更したい場合はこのメソッドを上書きしてください。
  # # @return [Authorizer]
  # def authorizer
  #   @authorizer ||= Authorizer.new(current_user)
  # end
end
```

authorize_action メソッドを使うことで、すべてのアクションの前に自動で authorize! を呼ぶことができます

```ruby
class DocumentController <_ApplicationController
  before_action :find_project
  authorize_action class_kwargs: -> { {project: @project} } # クラスに対して authorize_to_* メソッドを呼ぶときの追加の引数を lambda で指定

  def index
    # authorize_action により Document.authorize_to_index(current_user, project: project) が呼ばれます。
    # ...
  end

  def show
    # authorize_action により @document.authorize_to_show(current_user) が呼ばれます。
    # ...
  end

  private
  # デフォルトで index, new, create のみクラスに対して、それ以外はインスタンスに対して authorize_to_* メソッドが呼ばれます。
  # この挙動を変更するには下記メソッドを上書きしてください。
  # # @return [Set<Symbol>]
  # def actions_for_class
  #   @actions_for_class ||= Set.new(%i(index new create))
  # end
end
```

authorize_action についての詳しい情報は `Canny::Rails::ControllerHelper::ClassMethods#authorize_resource` のドキュメントを参照してください。

また、`can?`, `cannot?`, `can`, `cannot` メソッドについてもコントローラ及びビューで使用することができます。

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/canny.


## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
