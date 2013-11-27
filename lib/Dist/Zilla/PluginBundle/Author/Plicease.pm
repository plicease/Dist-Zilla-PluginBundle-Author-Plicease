package Dist::Zilla::PluginBundle::Author::Plicease;

use Moose;
use v5.10;
use Dist::Zilla;
use PerlX::Maybe qw( maybe );

# ABSTRACT: Dist::Zilla plugin bundle used by Plicease
# VERSION

=head1 SYNOPSIS

In your dist.ini:

 [@Author::Plicease]

=head1 DESCRIPTION

This Dist::Zilla plugin bundle is the equivalent to

 # Basic - UploadToCPAN, Readme, ExtraTests, and ConfirmRelease
 [GatherDir]
 [PruneCruft]
 except = .travis.yml
 [ManifestSkip]
 [MetaYAML]
 [License]
 [ExecDir]
 [ShareDir]
 [MakeMaker]
 [Manifest]
 [TestRelease]
 
 [Author::Plicease::PrePodWeaver]
 [PodWeaver]
 [NextRelease]
 format = %-9v %{yyyy-MM-dd HH:mm:ss Z}d
 [AutoPrereqs]
 [OurPkgVersion]
 [MetaJSON]
 
 [@Git]
 allow_dirty = dist.ini
 allow_dirty = Changes
 allow_dirty = README.md
 
 [AutoMetaResources]
 bugtracker.github = user:plicease
 repository.github = user:plicease
 homepage = http://perl.wdlabs.com/%{dist}/
 
 [Author::Plicease::TransformTravis]
 
 [InstallGuide]
 [MinimumPerl]
 [ConfirmRelease] 
 
 [ReadmeAnyFromPod]
 type     = text
 filename = README
 location = build
 
 [ReadmeAnyFromPod / ReadMePodInRoot]
 type     = markdown
 filename = README.md
 location = root
 
 [Author::Plicease::MarkDownCleanup]
 [Author::Plicease::Recommend]

=head1 OPTIONS

=head2 installer

Specify an alternative to L<[MakeMaker]|Dist::Zilla::Plugin::MakeMaker>
(L<[ModuleBuild]|Dist::Zilla::Plugin::ModuleBuild>,
L<[ModuleBuildTiny]|Dist::Zilla::Plugin::ModuleBuildTiny>, or
L<[ModuleBuildDatabase]|Dist::Zilla::Plugin::ModuleBuildDatabase> for example).

If installer is L<Alien|Dist::Zilla::Plugin::Alien>, then any options 
with the alien_ prefix will be passed to L<Alien|Dist::Zilla::Plugin::Alien>
(minus the alien_ prefix).

If installer is L<ModuleBuild|Dist::Zilla::Plugin::ModuleBuild>, then any
options with the mb_ prefix will be passed to L<ModuleBuild|Dist::Zilla::Plugin::ModuleBuild>
(including the mb_ prefix).

=head2 readme_from

Which file to pull from for the Readme (must be POD format).  If not 
specified, then the main module will be used.

=head2 release_tests

If set to true, then include release tests when building.

=head2 release_tests_skip

Passed into the L<Author::Plicease::Tests|Dist::Zilla::Plugin::Author::Plicease::Tests>
if C<release_tests> is true.

=head2 travis_status

if set to true, then include a link to the travis build page in the readme.

=head2 mb_class

if builder = ModuleBuild, this is the mb_class passed into the [ModuleBuild]
plugin.

=head1 SEE ALSO

L<Author::Plicease::Init|Dist::Zilla::Plugin::Author::Plicease::Init>,
L<MintingProfile::Plicease|Dist::Zilla::MintingProfile::Author::Plicease>

=cut

with 'Dist::Zilla::Role::PluginBundle::Easy';

use namespace::autoclean;

sub mvp_multivalue_args { qw( alien_build_command alien_install_command ) }

sub configure
{
  my($self) = @_;

  $self->add_plugins(
    'GatherDir',
    [ PruneCruft => { except => '.travis.yml' } ],
    'ManifestSkip',
    'MetaYAML',
    'License',
    'ExecDir',
    'ShareDir',
  );
  
  my $installer = $self->payload->{installer} // 'MakeMaker';
  if($installer eq 'Alien')
  {
    my %args = 
      map { $_ => $self->payload->{"alien_$_"} }
      map { s/^alien_//; $_ } 
      grep /^alien_/, keys %{ $self->payload };
    $self->add_plugins([ Alien => \%args ]);
  }
  elsif($installer eq 'ModuleBuild')
  {
    my %args = 
      map { $_ => $self->payload->{$_} }
      grep /^mb_/, keys %{ $self->payload };
    $self->add_plugins([ ModuleBuild => \%args ]);
  }
  else
  {
    $self->add_plugins($installer);
  }
  
  $self->add_plugins(
    'Manifest',
    'TestRelease',
  );
  
  
  $self->add_plugins(qw(

    Author::Plicease::PrePodWeaver
    PodWeaver
  ));
  
  $self->add_plugins([ NextRelease => { format => '%-9v %{yyyy-MM-dd HH:mm:ss Z}d' }]);
    
  $self->add_plugins(qw(
    AutoPrereqs
    OurPkgVersion
    MetaJSON

  ));

  $self->add_bundle('Git' => {
    allow_dirty => [ qw( dist.ini Changes README.md ) ],
  });

  $self->add_plugins([
    AutoMetaResources => {
      'bugtracker.github' => 'user:plicease',
      'repository.github' => 'user:plicease',
      homepage            => 'http://perl.wdlabs.com/%{dist}/',
    }
  ]);

  if($self->payload->{release_tests})
  {
    if($self->payload->{release_tests_skip})
    {
      $self->add_plugins([ 'Author::Plicease::Tests' => { skip => $self->payload->{release_tests_skip} }])
    }
    else
    {
      $self->add_plugins('Author::Plicease::Tests')
    }
  }
    
  $self->add_plugins(qw(

    Author::Plicease::TransformTravis
    InstallGuide
    MinimumPerl
    ConfirmRelease

  ));
  
  $self->add_plugins([
    'ReadmeAnyFromPod' => {
            type            => 'text',
            filename        => 'README',
            location        => 'build', 
      maybe source_filename => $self->payload->{readme_from},
    },
  ]);
  
  $self->add_plugins([
    'ReadmeAnyFromPod' => ReadMePodInRoot => {
      type                  => 'markdown',
      filename              => 'README.md',
      location              => 'root',
      maybe source_filename => $self->payload->{readme_from},
    },
  ]);
  
  $self->add_plugins([
    'Author::Plicease::MarkDownCleanup' => {
      travis_status => int($self->payload->{travis_status}//0),
    },
  ]);
  
  $self->add_plugins(qw( Author::Plicease::Recommend ));
}

__PACKAGE__->meta->make_immutable;

1;
