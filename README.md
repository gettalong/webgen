# webgen - static website generation made easy

webgen is used for generating static websites from templates and content
files (which can be written in any markup language). It can generate
dynamic content like menus on the fly and comes with many powerful
extensions.


## Contact & Help

The author of webgen is Thomas Leitner -- he is reachable at <mailto:t_leitner@gmx.at>.

You can discuss webgen or find help on the [webgen-users] mailing list
which is mirrored to the [webgen-users Google group].

Or you can join the IRC channel [#webgen] on Freenode.

[webgen-users]: http://rubyforge.org/pipermail/webgen-users/
[webgen-users Google group]: https://groups.google.com/forum/?fromgroups#!forum/webgen-users
[#webgen]: irc://chat.freenode.net/#webgen


## Description

webgen is a free (GPL-licensed) command line application for generating
static websites. It combines content with template files to generate
HTML files. This allows one to separate the content from the layout and
reuse the layout for many content files.

Apart from this basic functionality, webgen offers many features that
makes authoring websites easier:

* Multiple markup languages to choose from for writing HTML and CSS
  files (Markdown, Textile, RDoc, Haml, Sass ...)

* Automatic generation of menus, breadcrumb trails, ... and more!

* Partial website regeneration (only modified items get re-generated)
  which reduces website generation time enormously

* Self-contained website (all generated links are relative, so one can
  view the website *without a web server*)

* Easily extendable (all major components can be extended with new
  functionality)

* No need to know the Ruby language for basic websites

The main documentation lives at <http://webgen.rubyforge.org/documentation/>.


## Installation

webgen is written in Ruby, so you need the Ruby interpreter on your
system. You can get it from http://ruby-lang.org/. See
<http://webgen.rubyforge.org/installation.html> for more information.

You can install webgen via Rubygems:

    $ gem install webgen

Or via the `setup.rb` method if you have downloaded a tarball or zip file:

    $ ruby setup.rb config
    $ ruby setup.rb setup
    $ ruby setup.rb install


## License

GPLv3 - see the **COPYING** file.
