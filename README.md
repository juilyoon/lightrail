![Lightrail](https://github.com/lightness/lightrail/raw/master/logo.png)
============
[![Build Status](https://secure.travis-ci.org/lightness/lightrail.png?branch=master)](http://travis-ci.org/lightness/lightrail)

Lightrail is a minimalist Ruby stack for apps that serve primarily JSON APIs.
If [Sinatra][sinatra] doesn't give you enough, but [Rails][rails] is still too much, Lightrail is for you.

[sinatra]: http://www.sinatrarb.com/
[rails]: http://rubyonrails.org/

Join the mailing list by sending a message to: lightrail@librelist.com

Getting Started
---------------

Install the lightrail gem:

`gem install lightrail`

Like Rails, installing the lightrail gem will install a command line utility
called 'lightrail'. This command is in fact identical to the 'rails' command,
but just tweaked for Lightrail defaults instead of Rails defaults.

You can use 'lightrail' to create a new application skeleton just like Rails:

`lightrail new myapp`

The skeleton application that Lightrail generates is identical to a standard
Rails application, with only these changes:

* Gemfile pulls in lightrail instead of rails
* application.rb pulls in lightrail instead of rails
* ApplicationController descends from Lightrail::ActionController::Metal
  instead of ActionController::Base. ActionView is not used or installed.

Once you've created your application, run:

`lightrail server`

to launch a web server in the development environment (just like Rails!)

You can convert an existing Rails 3 application to a Lightrail application
by retrofitting the changes mentioned above.

Lightrail::ActionController::Metal
----------------------------------

A lightweight `ActionController::Base` replacement designed for when APIs are your main concern.
It removes several irrelevant modules and also provides following additional behaviors:

  * `halt` stops rendering at any point using Ruby's throw/catch mechanism.
    Any option passed to `halt` is forwarded to the `render` method

  * `render :errors` is a renderer extension that allows you to easily render an error as JSON.
    It is simply a convenience method for `render json: errors, status: 422`.
    With the `halt` mechanism above you'll see this common pattern: `halt errors: { request: "invalid" }`.


Lightrail::Wrapper
------------------

A wrapper functionality to make easier JSON responses.
It is divided in three main parts:

**Creating A Wrapper**

Each model needs to have a wrapper in order to be rendered as JSON.
Instead of using several options (like `:only`, `:method`, and friends) it expects you to explicitly define the hash to returned through the `view` method.
Here is an example:

``` ruby
class AccountWrapper < Lightrail::Wrapper::Model
  has_one :credit_card
  has_one :subscription

  def view
    attributes = [:id, :name, :user_id]

    if owner?
      attributes.concat [:billing_address, :billing_country]
    end

    # Shortcut for account.attributes.slice()
    hash = account.slice(*attributes)
    hash[:owner] = owner?
    hash
  end

  # Whenever an association method is defined explicitly
  # it is given higher preference. That said, whenever
  # including a credit_card, it will invoke this method
  # instead of calling account.credit_card directly.
  def credit_card
    account.credit_card if owner?
  end

  protected

  def owner?
    account.owners.include? scope
  end
end
```

A wrapper is initialized with two arguments:
the `resource` which is the `account` in this case and a `scope`.
In most cases the scope is the `current_user`.
The idea of having a scope inside the wrapper is to be able to properly handle permissions when exposing a resource.
In the example above you can notice that a `credit_card` is only exposed if the user actually owns the account being showed.
Billing information is also hidden except when the user is an `owner?`.

Another convenience is that the wrapper can automatically handle associations.
Associations, when exposed are not nested exposed but rather flat in the JSON here is an example:


``` json
{
  "account": {
    "id": 1,
    "name": "Main",
    "user_id": null,
    "credit_card_id": 1
  },

  "credit_cards": {
    "id": 1,
    "last_4": "3232"
  }
}
```

In order to render a wrapper with its associations you can use the `render` method and pass the associations explicitly:

``` ruby
AccountWrapper.new(@account, current_user).render include: [:credit_card]
```

Although most of the times this will be done automatically by the controller.

**Using The Wrapper In The Controller**

`Lightrail::Wrapper::Controller` provides several facilities to use wrappers from the controller:

  * `#json(resources)` is the main method.
    Given a resource (or an array of resources) it will find the proper wrapper and render it.
    Any include given at `params[:include]` will be validated and passed to the underlying wrapper.
    Consider the following action:

    ``` ruby
    def last
      json Account.last
    end
    ```

    When accessed as `/accounts/last` it won't return any credit card or subscription resource in the JSON, unless it is given explicitly as `/accounts/last?include=credit_cards,subscriptions` (in plural).

    In order for the `json` method to work, a `wrapper_scope` needs to be defined.
    You can usually define it in your `ApplicationController` as follow:

    ``` ruby
    def wrapper_scope
      current_user
    end
    ```

  * `errors(resource)` is a method that makes pair with `json(resource)`.
    It basically receives a resource and render its errors.
    For instance, `errors(account)` will return `:errors => { :account => account.errors }`;

  * `wrap_array(resources)` as the `json` method accepts extra associations to be included through `params[:include]` we need to be careful to not do `N+1` db queries.
    This can be fixed by using the `wrap_array` method that will automatically wrap the given array and preload all associations.
    For instance, you want will to do this in your `index` actions:

    ``` ruby
    def index
      json wrap_array(current_user.accounts.active.all)
    end
    ```

**Active Record Extensions**

`Lightrail::Wrapper` provides one Active Record extension method called `#slice()`.
In order to understand what it does, it is easier to look at the source:

``` ruby
def slice(*keys)
  keys.map! { |key| key.to_s }
  attributes.slice(*keys)
end
```

This method was used in the example showed above.


config.lightrail.*
------------------

Lightrail adds a `config.lightrail` namespace to your application with two main methods:

  * `remove_session_middlewares!` removes `ActionDispatch::Cookies`,
  `ActionDispatch::Session::CookieStore` and `ActionDispatch::Flash` middlewares.
  * `remove_browser_middlewares!` removes the `ActionDispatch::BestStandardsSupport` middleware.

