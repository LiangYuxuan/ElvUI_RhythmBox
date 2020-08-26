#!/usr/bin/env bash

# fetch.sh fetch external library from remote Git, SVN, or Mercurial repo.
# Based on release.sh (https://github.com/BigWigsMods/packager)
#
# This is free and unencumbered software released into the public domain.
#
# Anyone is free to copy, modify, publish, use, compile, sell, or
# distribute this software, either in source code form or as a compiled
# binary, for any purpose, commercial or non-commercial, and by any
# means.
#
# In jurisdictions that recognize copyright laws, the author or authors
# of this software dedicate any and all copyright interest in the
# software to the public domain. We make this dedication for the benefit
# of the public at large and to the detriment of our heirs and
# successors. We intend this dedication to be an overt act of
# relinquishment in perpetuity of all present and future rights to this
# software under copyright law.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
# IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR
# OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
# ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
# OTHER DEALINGS IN THE SOFTWARE.
#
# For more information, please refer to <http://unlicense.org/>

## USER OPTIONS

# Variables set via command-line options
topdir=
checkoutdir=
line_ending="dos"
pkgmeta_file=

## END USER OPTIONS


# Process command-line options
usage() {
	echo "Usage: fetch.sh [-u] [-t topdir] [-c checkoutdir] [-m pkgmeta.yml]" >&2
	echo "  -u               Use Unix line-endings." >&2
	echo "  -t topdir        Set top-level directory of checkout." >&2
	echo "  -c checkoutdir   Set directory containing the checkout directory. Defaults to \"\$topdir/.checkout\"." >&2
	echo "  -m pkgmeta.yaml  Set the pkgmeta file to use." >&2
}

OPTIND=1
while getopts ":ut:c:m:" opt; do
	case $opt in
	c)
		# Set the checkout directory to a non-default value.
		checkoutdir="$OPTARG"
		;;
	t)
		# Set the top-level directory of the checkout to a non-default value.
		if [ ! -d "$OPTARG" ]; then
			echo "Invalid argument for option \"-t\" - Directory \"$OPTARG\" does not exist." >&2
			usage
			exit 1
		fi
		topdir="$OPTARG"
		;;
	u)
		# Skip Unix-to-DOS line-ending translation.
		line_ending=unix
		;;
	m)
		# Set the pkgmeta file.
		if [ ! -f "$OPTARG" ]; then
			echo "Invalid argument for option \"-m\" - File \"$OPTARG\" does not exist." >&2
			usage
			exit 1
		fi
		pkgmeta_file="$OPTARG"
		;;
	:)
		echo "Option \"-$OPTARG\" requires an argument." >&2
		usage
		exit 1
		;;
	\?)
		if [ "$OPTARG" != "?" ] && [ "$OPTARG" != "h" ]; then
			echo "Unknown option \"-$OPTARG\"." >&2
		fi
		usage
		exit 1
		;;
	esac
done
shift $((OPTIND - 1))

# Set $topdir to top-level directory of the checkout.
if [ -z "$topdir" ]; then
	dir=$( pwd )
	if [ -d "$dir/.git" ] || [ -d "$dir/.svn" ] || [ -d "$dir/.hg" ]; then
		topdir=.
	else
		dir=${dir%/*}
		topdir=".."
		while [ -n "$dir" ]; do
			if [ -d "$topdir/.git" ] || [ -d "$topdir/.svn" ] || [ -d "$topdir/.hg" ]; then
				break
			fi
			dir=${dir%/*}
			topdir="$topdir/.."
		done
		if [ ! -d "$topdir/.git" ] && [ ! -d "$topdir/.svn" ] && [ ! -d "$topdir/.hg" ]; then
			echo "No Git, SVN, or Hg checkout found." >&2
			exit 1
		fi
	fi
fi

# Set $checkoutdir to the directory which will contain the generated addon zipfile.
if [ -z "$checkoutdir" ]; then
	checkoutdir="$topdir/.checkout"
fi

# Set $basedir to the basename of the checkout directory.
basedir=$( cd "$topdir" && pwd )
case $basedir in
/*/*)
	basedir=${basedir##/*/}
	;;
/*)
	basedir=${basedir##/}
	;;
esac

# Set $repository_type to "git" or "svn" or "hg".
repository_type=
if [ -d "$topdir/.git" ]; then
	repository_type=git
elif [ -d "$topdir/.svn" ]; then
	repository_type=svn
elif [ -d "$topdir/.hg" ]; then
	repository_type=hg
else
	echo "No Git, SVN, or Hg checkout found in \"$topdir\"." >&2
	exit 1
fi

# $checkoutdir must be an absolute path or inside $topdir.
case $checkoutdir in
/*)			;;
$topdir/*)	;;
*)
	echo "The checkout directory \"$checkoutdir\" must be an absolute path or inside \"$topdir\"." >&2
	exit 1
	;;
esac

# Create the staging directory.
mkdir -p "$checkoutdir" 2>/dev/null || {
	echo "Unable to create the checkout directory \"$checkoutdir\"." >&2
	exit 1
}

# Expand $topdir and $checkoutdir to their absolute paths for string comparisons later.
topdir=$( cd "$topdir" && pwd )
checkoutdir=$( cd "$checkoutdir" && pwd )

###
### set_info_<repo> returns the following information:
###
si_repo_type= # "git" or "svn" or "hg"
si_repo_dir= # the checkout directory
si_repo_url= # the checkout url
si_tag= # tag for HEAD
si_previous_tag= # previous tag
si_previous_revision= # [SVN|Hg] revision number for previous tag

si_project_revision= # Turns into the highest revision of the entire project in integer form, e.g. 1234, for SVN. Turns into the commit count for the project's hash for Git.
si_project_hash= # [Git|Hg] Turns into the hash of the entire project in hex form. e.g. 106c634df4b3dd4691bf24e148a23e9af35165ea
si_project_abbreviated_hash= # [Git|Hg] Turns into the abbreviated hash of the entire project in hex form. e.g. 106c63f
si_project_author= # Turns into the last author of the entire project. e.g. ckknight
si_project_date_iso= # Turns into the last changed date (by UTC) of the entire project in ISO 8601. e.g. 2008-05-01T12:34:56Z
si_project_date_integer= # Turns into the last changed date (by UTC) of the entire project in a readable integer fashion. e.g. 2008050123456
si_project_timestamp= # Turns into the last changed date (by UTC) of the entire project in POSIX timestamp. e.g. 1209663296
si_project_version= # Turns into an approximate version of the project. The tag name if on a tag, otherwise it's up to the repo. SVN returns something like "r1234", Git returns something like "v0.1-873fc1"

si_file_revision= # Turns into the current revision of the file in integer form, e.g. 1234, for SVN. Turns into the commit count for the file's hash for Git.
si_file_hash= # Turns into the hash of the file in hex form. e.g. 106c634df4b3dd4691bf24e148a23e9af35165ea
si_file_abbreviated_hash= # Turns into the abbreviated hash of the file in hex form. e.g. 106c63
si_file_author= # Turns into the last author of the file. e.g. ckknight
si_file_date_iso= # Turns into the last changed date (by UTC) of the file in ISO 8601. e.g. 2008-05-01T12:34:56Z
si_file_date_integer= # Turns into the last changed date (by UTC) of the file in a readable integer fashion. e.g. 20080501123456
si_file_timestamp= # Turns into the last changed date (by UTC) of the file in POSIX timestamp. e.g. 1209663296

# SVN date helper function
isgnudate=$( date --version &>/dev/null && echo "true" )
strtotime() {
	value="$1" # datetime string
	format="$2" # strptime string
	if [ -n "$isgnudate" ]; then # gnu
		date -d "$value" +%s 2>/dev/null
	else # bsd
		date -j -f "$format" "$value" "+%s" 2>/dev/null
	fi
}

set_info_git() {
	si_repo_dir="$1"
	si_repo_type="git"
	si_repo_url=$( git -C "$si_repo_dir" remote get-url origin 2>/dev/null | sed -e 's/^git@\(.*\):/https:\/\/\1\//' )
	if [ -z "$si_repo_url" ]; then # no origin so grab the first fetch url
		si_repo_url=$( git -C "$si_repo_dir" remote -v | awk '/(fetch)/ { print $2; exit }' | sed -e 's/^git@\(.*\):/https:\/\/\1\//' )
	fi

	# Populate filter vars.
	si_project_hash=$( git -C "$si_repo_dir" show --no-patch --format="%H" 2>/dev/null )
	si_project_abbreviated_hash=$( git -C "$si_repo_dir" show --no-patch --format="%h" 2>/dev/null )
	si_project_author=$( git -C "$si_repo_dir" show --no-patch --format="%an" 2>/dev/null )
	si_project_timestamp=$( git -C "$si_repo_dir" show --no-patch --format="%at" 2>/dev/null )
	si_project_date_iso=$( TZ= date -jf "%s" "$si_project_timestamp" +%Y-%m-%dT%H:%M:%SZ 2>/dev/null )
	si_project_date_integer=$( TZ= date -jf "%s" "$si_project_timestamp" +%Y%m%d%H%M%S 2>/dev/null )
	# XXX --depth limits rev-list :\ [ ! -s "$(git rev-parse --git-dir)/shallow" ] || git fetch --unshallow --no-tags
	si_project_revision=$( git -C "$si_repo_dir" rev-list --count "$si_project_hash" 2>/dev/null )

	# Get the tag for the HEAD.
	si_previous_tag=
	si_previous_revision=
	_si_tag=$( git -C "$si_repo_dir" describe --tags --always 2>/dev/null )
	si_tag=$( git -C "$si_repo_dir" describe --tags --always --abbrev=0 2>/dev/null )
	# Set $si_project_version to the version number of HEAD. May be empty if there are no commits.
	si_project_version=$si_tag
	# The HEAD is not tagged if the HEAD is several commits past the most recent tag.
	if [ "$si_tag" = "$si_project_hash" ]; then
		# --abbrev=0 expands out the full sha if there was no previous tag
		si_project_version=$_si_tag
		si_previous_tag=
		si_tag=
	elif [ "$_si_tag" != "$si_tag" ]; then
		# not on a tag
		si_project_version=$( git -C "$si_repo_dir" describe --tags --exclude="*alpha*" 2>/dev/null )
		si_previous_tag=$( git -C "$si_repo_dir" describe --tags --abbrev=0 --exclude="*alpha*" 2>/dev/null )
		si_tag=
	else # we're on a tag, just jump back one commit
		if [[ $si_tag != *"beta"* && $si_tag != *"alpha"* ]]; then
			# full release, ignore beta tags
			si_previous_tag=$( git -C "$si_repo_dir" describe --tags --abbrev=0 --exclude="*alpha*" --exclude="*beta*" HEAD~ 2>/dev/null )
		else
			si_previous_tag=$( git -C "$si_repo_dir" describe --tags --abbrev=0 --exclude="*alpha*" HEAD~ 2>/dev/null )
		fi
	fi
}

set_info_svn() {
	si_repo_dir="$1"
	si_repo_type="svn"

	# Temporary file to hold results of "svn info".
	_si_svninfo="${si_repo_dir}/.svn/release_sh_svninfo"
	svn info -r BASE "$si_repo_dir" 2>/dev/null > "$_si_svninfo"

	if [ -s "$_si_svninfo" ]; then
		_si_root=$( awk '/^Repository Root:/ { print $3; exit }' < "$_si_svninfo" )
		_si_url=$( awk '/^URL:/ { print $2; exit }' < "$_si_svninfo" )
		_si_revision=$( awk '/^Last Changed Rev:/ { print $NF; exit }' < "$_si_svninfo" )
		si_repo_url=$_si_root

		case ${_si_url#${_si_root}/} in
		tags/*)
			# Extract the tag from the URL.
			si_tag=${_si_url#${_si_root}/tags/}
			si_tag=${si_tag%%/*}
			si_project_revision="$_si_revision"
			;;
		*)
			# Check if the latest tag matches the working copy revision (/trunk checkout instead of /tags)
			_si_tag_line=$( svn log --verbose --limit 1 "$_si_root/tags" 2>/dev/null | awk '/^   A/ { print $0; exit }' )
			_si_tag=$( echo "$_si_tag_line" | awk '/^   A/ { print $2 }' | awk -F/ '{ print $NF }' )
			_si_tag_from_revision=$( echo "$_si_tag_line" | sed -e 's/^.*:\([0-9]\{1,\}\)).*$/\1/' ) # (from /project/trunk:N)

			if [ "$_si_tag_from_revision" = "$_si_revision" ]; then
				si_tag="$_si_tag"
				si_project_revision=$( svn info "$_si_root/tags/$si_tag" 2>/dev/null | awk '/^Last Changed Rev:/ { print $NF; exit }' )
			else
				# Set $si_project_revision to the highest revision of the project at the checkout path
				si_project_revision=$( svn info --recursive "$si_repo_dir" 2>/dev/null | awk '/^Last Changed Rev:/ { print $NF }' | sort -nr | head -1 )
			fi
			;;
		esac

		if [ -n "$si_tag" ]; then
			si_project_version="$si_tag"
		else
			si_project_version="r$si_project_revision"
		fi

		# Get the previous tag and it's revision
		_si_limit=$((si_project_revision - 1))
		_si_tag=$( svn log --verbose --limit 1 "$_si_root/tags" -r $_si_limit:1 2>/dev/null | awk '/^   A/ { print $0; exit }' | awk '/^   A/ { print $2 }' | awk -F/ '{ print $NF }' )
		if [ -n "$_si_tag" ]; then
			si_previous_tag="$_si_tag"
			si_previous_revision=$( svn info "$_si_root/tags/$_si_tag" 2>/dev/null | awk '/^Last Changed Rev:/ { print $NF; exit }' )
		fi

		# Populate filter vars.
		si_project_author=$( awk '/^Last Changed Author:/ { print $0; exit }' < "$_si_svninfo" | cut -d" " -f4- )
		_si_timestamp=$( awk '/^Last Changed Date:/ { print $4,$5,$6; exit }' < "$_si_svninfo" )
		si_project_timestamp=$( strtotime "$_si_timestamp" "%F %T %z" )
		si_project_date_iso=$( TZ= date -jf "%s" "$si_project_timestamp" +%Y-%m-%dT%H:%M:%SZ 2>/dev/null )
		si_project_date_integer=$( TZ= date -jf "%s" "$si_project_timestamp" +%Y%m%d%H%M%S 2>/dev/null )
		# SVN repositories have no project hash.
		si_project_hash=
		si_project_abbreviated_hash=

		rm -f "$_si_svninfo" 2>/dev/null
	fi
}

set_info_hg() {
	si_repo_dir="$1"
	si_repo_type="hg"
	si_repo_url=$( hg --cwd "$si_repo_dir" paths -q default )
	if [ -z "$si_repo_url" ]; then # no default so grab the first path
		si_repo_url=$( hg --cwd "$si_repo_dir" paths | awk '{ print $3; exit }' )
	fi

	# Populate filter vars.
	si_project_hash=$( hg --cwd "$si_repo_dir" log -r . --template '{node}' 2>/dev/null )
	si_project_abbreviated_hash=$( hg --cwd "$si_repo_dir" log -r . --template '{node|short}' 2>/dev/null )
	si_project_author=$( hg --cwd "$si_repo_dir" log -r . --template '{author}' 2>/dev/null )
	si_project_timestamp=$( hg --cwd "$si_repo_dir" log -r . --template '{date}' 2>/dev/null | cut -d. -f1 )
	si_project_date_iso=$( TZ= date -jf "%s" "$si_project_timestamp" +%Y-%m-%dT%H:%M:%SZ 2>/dev/null )
	si_project_date_integer=$( TZ= date -jf "%s" "$si_project_timestamp" +%Y%m%d%H%M%S 2>/dev/null )
	si_project_revision=$( hg --cwd "$si_repo_dir" log -r . --template '{rev}' 2>/dev/null )

	# Get tag info
	si_tag=
	# I'm just muddling through revsets, so there is probably a better way to do this
	# Ignore tag commits, so v1.0-1 will package as v1.0
	if [ "$( hg --cwd "$si_repo_dir" log -r '.-filelog(.hgtags)' --template '{rev}' 2>/dev/null )" == "" ]; then
		_si_tip=$( hg --cwd "$si_repo_dir" log -r 'last(parents(.))' --template '{rev}' 2>/dev/null )
	else
		_si_tip=$( hg --cwd "$si_repo_dir" log -r . --template '{rev}' 2>/dev/null )
	fi
	si_previous_tag=$( hg --cwd "$si_repo_dir" log -r "$_si_tip" --template '{latesttag}' 2>/dev/null )
	# si_project_version=$( hg --cwd "$si_repo_dir" log -r "$_si_tip" --template "{ ifeq(changessincelatesttag, 0, latesttag, '{latesttag}-{changessincelatesttag}-m{node|short}') }" 2>/dev/null ) # git style
	si_project_version=$( hg --cwd "$si_repo_dir" log -r "$_si_tip" --template "{ ifeq(changessincelatesttag, 0, latesttag, 'r{rev}') }" 2>/dev/null ) # svn style
	if [ "$si_previous_tag" = "$si_project_version" ]; then
		# we're on a tag
		si_tag=$si_previous_tag
		si_previous_tag=$( hg --cwd "$si_repo_dir" log -r "last(parents($_si_tip))" --template '{latesttag}' 2>/dev/null )
	fi
	si_previous_revision=$( hg --cwd "$si_repo_dir" log -r "$si_previous_tag" --template '{rev}' 2>/dev/null )
}

set_info_file() {
	if [ "$si_repo_type" = "git" ]; then
		_si_file=${1#si_repo_dir} # need the path relative to the checkout
		# Populate filter vars from the last commit the file was included in.
		si_file_hash=$( git -C "$si_repo_dir" log --max-count=1 --format="%H" "$_si_file" 2>/dev/null )
		si_file_abbreviated_hash=$( git -C "$si_repo_dir" log --max-count=1  --format="%h"  "$_si_file" 2>/dev/null )
		si_file_author=$( git -C "$si_repo_dir" log --max-count=1 --format="%an" "$_si_file" 2>/dev/null )
		si_file_timestamp=$( git -C "$si_repo_dir" log --max-count=1 --format="%at" "$_si_file" 2>/dev/null )
		si_file_date_iso=$( TZ= date -jf "%s" "$si_file_timestamp" +%Y-%m-%dT%H:%M:%SZ 2>/dev/null )
		si_file_date_integer=$( TZ= date -jf "%s" "$si_file_timestamp" +%Y%m%d%H%M%S 2>/dev/null )
		si_file_revision=$( git -C "$si_repo_dir" rev-list --count "$si_file_hash" 2>/dev/null ) # XXX checkout depth affects rev-list, see set_info_git
	elif [ "$si_repo_type" = "svn" ]; then
		_si_file="$1"
		# Temporary file to hold results of "svn info".
		_sif_svninfo="${si_repo_dir}/.svn/release_sh_svnfinfo"
		svn info "$_si_file" 2>/dev/null > "$_sif_svninfo"
		if [ -s "$_sif_svninfo" ]; then
			# Populate filter vars.
			si_file_revision=$( awk '/^Last Changed Rev:/ { print $NF; exit }' < "$_sif_svninfo" )
			si_file_author=$( awk '/^Last Changed Author:/ { print $0; exit }' < "$_sif_svninfo" | cut -d" " -f4- )
			_si_timestamp=$( awk '/^Last Changed Date:/ { print $4,$5,$6; exit }' < "$_sif_svninfo" )
			si_file_timestamp=$( strtotime "$_si_timestamp" "%F %T %z" )
			si_file_date_iso=$( TZ= date -jf "%s" "$si_file_timestamp" +%Y-%m-%dT%H:%M:%SZ 2>/dev/null )
			si_file_date_integer=$( TZ= date -jf "%s" "$si_file_timestamp" +%Y%m%d%H%M%S 2>/dev/null )
			# SVN repositories have no project hash.
			si_file_hash=
			si_file_abbreviated_hash=

			rm -f "$_sif_svninfo" 2>/dev/null
		fi
	elif [ "$si_repo_type" = "hg" ]; then
		_si_file=${1#si_repo_dir} # need the path relative to the checkout
		# Populate filter vars.
		si_file_hash=$( hg --cwd "$si_repo_dir" log --limit 1 --template '{node}' "$_si_file" 2>/dev/null )
		si_file_abbreviated_hash=$( hg --cwd "$si_repo_dir" log --limit 1 --template '{node|short}' "$_si_file" 2>/dev/null )
		si_file_author=$( hg --cwd "$si_repo_dir" log --limit 1 --template '{author}' "$_si_file" 2>/dev/null )
		si_file_timestamp=$( hg --cwd "$si_repo_dir" log --limit 1 --template '{date}' "$_si_file" 2>/dev/null | cut -d. -f1 )
		si_file_date_iso=$( TZ= date -jf "%s" "$si_file_timestamp" +%Y-%m-%dT%H:%M:%SZ 2>/dev/null )
		si_file_date_integer=$( TZ= date -jf "%s" "$si_file_timestamp" +%Y%m%d%H%M%S 2>/dev/null )
		si_file_revision=$( hg --cwd "$si_repo_dir" log --limit 1 --template '{rev}' "$_si_file" 2>/dev/null )
	fi
}

# Bare carriage-return character.
carriage_return=$( printf "\r" )

# Returns 0 if $1 matches one of the colon-separated patterns in $2.
match_pattern() {
	_mp_file=$1
	_mp_list="$2:"
	while [ -n "$_mp_list" ]; do
		_mp_pattern=${_mp_list%%:*}
		_mp_list=${_mp_list#*:}
		case $_mp_file in
		$_mp_pattern)
			return 0
			;;
		esac
	done
	return 1
}

# Simple .pkgmeta YAML processor.
yaml_keyvalue() {
	yaml_key=${1%%:*}
	yaml_value=${1#$yaml_key:}
	yaml_value=${yaml_value#"${yaml_value%%[! ]*}"} # trim leading whitespace
	yaml_value=${yaml_value#[\'\"]} # trim leading quotes
	yaml_value=${yaml_value%[\'\"]} # trim trailing quotes
}

yaml_listitem() {
	yaml_item=${1#-}
	yaml_item=${yaml_item#"${yaml_item%%[! ]*}"} # trim leading whitespace
}

###
### Create filters for pass-through processing of files to replace repository keywords.
###

# Filter for simple repository keyword replacement.
simple_filter() {
	sed \
		-e "s/@project-revision@/$si_project_revision/g" \
		-e "s/@project-hash@/$si_project_hash/g" \
		-e "s/@project-abbreviated-hash@/$si_project_abbreviated_hash/g" \
		-e "s/@project-author@/$si_project_author/g" \
		-e "s/@project-date-iso@/$si_project_date_iso/g" \
		-e "s/@project-date-integer@/$si_project_date_integer/g" \
		-e "s/@project-timestamp@/$si_project_timestamp/g" \
		-e "s/@project-version@/$si_project_version/g" \
		-e "s/@file-revision@/$si_file_revision/g" \
		-e "s/@file-hash@/$si_file_hash/g" \
		-e "s/@file-abbreviated-hash@/$si_file_abbreviated_hash/g" \
		-e "s/@file-author@/$si_file_author/g" \
		-e "s/@file-date-iso@/$si_file_date_iso/g" \
		-e "s/@file-date-integer@/$si_file_date_integer/g" \
		-e "s/@file-timestamp@/$si_file_timestamp/g"
}

lua_filter() {
	sed \
		-e "s/--@$1@/--[===[@$1@/g" \
		-e "s/--@end-$1@/--@end-$1@]===]/g" \
		-e "s/--\[===\[@non-$1@/--@non-$1@/g" \
		-e "s/--@end-non-$1@\]===\]/--@end-non-$1@/g"
}

toc_filter() {
	_trf_token=$1; shift
	_trf_comment=
	_trf_eof=
	while [ -z "$_trf_eof" ]; do
		IFS='' read -r _trf_line || _trf_eof="true"
		# Strip any trailing CR character.
		_trf_line=${_trf_line%$carriage_return}
		_trf_passthrough=
		case $_trf_line in
		"#@${_trf_token}@"*)
			_trf_comment="# "
			_trf_passthrough="true"
			;;
		"#@end-${_trf_token}@"*)
			_trf_comment=
			_trf_passthrough="true"
			;;
		esac
		if [ -z "$_trf_passthrough" ]; then
			_trf_line="$_trf_comment$_trf_line"
		fi
		if [ -n "$_trf_eof" ]; then
			echo -n "$_trf_line"
		else
			echo "$_trf_line"
		fi
	done
}

toc_filter2() {
	_trf_token=$1
	_trf_action=1
	if [ "$2" = "true" ]; then
		_trf_action=0
	fi
	shift 2
	_trf_keep=1
	_trf_uncomment=
	_trf_eof=
	while [ -z "$_trf_eof" ]; do
		IFS='' read -r _trf_line || _trf_eof="true"
		# Strip any trailing CR character.
		_trf_line=${_trf_line%$carriage_return}
		case $_trf_line in
		*"#@$_trf_token@"*)
			# remove the tokens, keep the content
			_trf_keep=$_trf_action
			;;
		*"#@non-$_trf_token@"*)
			# remove the tokens, remove the content
			_trf_keep=$(( 1-_trf_action ))
			_trf_uncomment="true"
			;;
		*"#@end-$_trf_token@"*|*"#@end-non-$_trf_token@"*)
			# remove the tokens
			_trf_keep=1
			_trf_uncomment=
			;;
		*)
			if (( _trf_keep )); then
				if [ -n "$_trf_uncomment" ]; then
					_trf_line="${_trf_line#\# }"
				fi
				if [ -n "$_trf_eof" ]; then
					echo -n "$_trf_line"
				else
					echo "$_trf_line"
				fi
			fi
			;;
		esac
	done
}

xml_filter() {
	sed \
		-e "s/<!--@$1@-->/<!--@$1/g" \
		-e "s/<!--@end-$1@-->/@end-$1@-->/g" \
		-e "s/<!--@non-$1@/<!--@non-$1@-->/g" \
		-e "s/@end-non-$1@-->/<!--@end-non-$1@-->/g"
}

do_not_package_filter() {
	_dnpf_token=$1; shift
	_dnpf_string="do-not-package"
	_dnpf_start_token=
	_dnpf_end_token=
	case $_dnpf_token in
	lua)
		_dnpf_start_token="--@$_dnpf_string@"
		_dnpf_end_token="--@end-$_dnpf_string@"
		;;
	toc)
		_dnpf_start_token="#@$_dnpf_string@"
		_dnpf_end_token="#@end-$_dnpf_string@"
		;;
	xml)
		_dnpf_start_token="<!--@$_dnpf_string@-->"
		_dnpf_end_token="<!--@end-$_dnpf_string@-->"
		;;
	esac
	if [ -z "$_dnpf_start_token" ] || [ -z "$_dnpf_end_token" ]; then
		cat
	else
		# Replace all content between the start and end tokens, inclusive, with a newline to match CF packager.
		_dnpf_eof=
		_dnpf_skip=
		while [ -z "$_dnpf_eof" ]; do
			IFS='' read -r _dnpf_line || _dnpf_eof="true"
			# Strip any trailing CR character.
			_dnpf_line=${_dnpf_line%$carriage_return}
			case $_dnpf_line in
			*$_dnpf_start_token*)
				_dnpf_skip="true"
				echo -n "${_dnpf_line%%${_dnpf_start_token}*}"
				;;
			*$_dnpf_end_token*)
				_dnpf_skip=
				if [ -z "$_dnpf_eof" ]; then
					echo ""
				fi
				;;
			*)
				if [ -z "$_dnpf_skip" ]; then
					if [ -n "$_dnpf_eof" ]; then
						echo -n "$_dnpf_line"
					else
						echo "$_dnpf_line"
					fi
				fi
				;;
			esac
		done
	fi
}

line_ending_filter() {
	_lef_eof=
	while [ -z "$_lef_eof" ]; do
		IFS='' read -r _lef_line || _lef_eof="true"
		# Strip any trailing CR character.
		_lef_line=${_lef_line%$carriage_return}
		if [ -n "$_lef_eof" ]; then
			# Preserve EOF not preceded by newlines.
			echo -n "$_lef_line"
		else
			case $line_ending in
			dos)
				# Terminate lines with CR LF.
				printf "%s\r\n" "$_lef_line"
				;;
			unix)
				# Terminate lines with LF.
				printf "%s\n" "$_lef_line"
				;;
			esac
		fi
	done
}

###
### Copy files from the working directory into the package directory.
###

# Copy of the contents of the source directory into the destination directory.
# Dotfiles and any files matching the ignore pattern are skipped.  Copied files
# are subject to repository keyword replacement.
#
copy_directory_tree() {
	_cdt_alpha=
	_cdt_debug=
	_cdt_ignored_patterns=
	_cdt_nolib=
	_cdt_do_not_package=
	_cdt_unchanged_patterns=
	_cdt_classic=
	OPTIND=1
	while getopts :adi:npu:c _cdt_opt "$@"; do
		case $_cdt_opt in
		a)	_cdt_alpha="true" ;;
		d)	_cdt_debug="true" ;;
		i)	_cdt_ignored_patterns=$OPTARG ;;
		n)	_cdt_nolib="true" ;;
		p)	_cdt_do_not_package="true" ;;
		u)	_cdt_unchanged_patterns=$OPTARG ;;
		c)	_cdt_classic="true"
		esac
	done
	shift $((OPTIND - 1))
	_cdt_srcdir=$1
	_cdt_destdir=$2

	echo "Copying files into ${_cdt_destdir#$topdir/}:"
	if [ ! -d "$_cdt_destdir" ]; then
		mkdir -p "$_cdt_destdir"
	fi
	# Create a "find" command to list all of the files in the current directory, minus any ones we need to prune.
	_cdt_find_cmd="find ."
	# Prune everything that begins with a dot except for the current directory ".".
	_cdt_find_cmd="$_cdt_find_cmd \( -name \".*\" -a \! -name \".\" \) -prune"
	# Prune the destination directory if it is a subdirectory of the source directory.
	_cdt_dest_subdir=${_cdt_destdir#${_cdt_srcdir}/}
	case $_cdt_dest_subdir in
	/*)	;;
	*)	_cdt_find_cmd="$_cdt_find_cmd -o -path \"./$_cdt_dest_subdir\" -prune" ;;
	esac
	# Print the filename, but suppress the current directory ".".
	_cdt_find_cmd="$_cdt_find_cmd -o \! -name \".\" -print"
	( cd "$_cdt_srcdir" && eval "$_cdt_find_cmd" ) | while read -r file; do
		file=${file#./}
		if [ -f "$_cdt_srcdir/$file" ]; then
			# Check if the file should be ignored.
			skip_copy=
			# Prefix external files with the relative topdir path
			_cdt_check_file=$file
			if [ -n "${_cdt_destdir#$topdir}" ]; then
				_cdt_check_file="${_cdt_destdir#$topdir/}/$file"
			fi
			# Skip files matching the colon-separated "ignored" shell wildcard patterns.
			if [ -z "$skip_copy" ] && match_pattern "$_cdt_check_file" "$_cdt_ignored_patterns"; then
				skip_copy="true"
			fi
			# Never skip files that match the colon-separated "unchanged" shell wildcard patterns.
			unchanged=
			if [ -n "$skip_copy" ] && match_pattern "$file" "$_cdt_unchanged_patterns"; then
				skip_copy=
				unchanged="true"
			fi
			# Copy unskipped files into $_cdt_destdir.
			if [ -n "$skip_copy" ]; then
				echo "  Ignoring: $file"
			else
				dir=${file%/*}
				if [ "$dir" != "$file" ]; then
					mkdir -p "$_cdt_destdir/$dir"
				fi
				# Check if the file matches a pattern for keyword replacement.
				skip_filter="true"
				if match_pattern "$file" "*.lua:*.md:*.toc:*.txt:*.xml"; then
					skip_filter=
				fi
				if [ -n "$skip_filter" ] || [ -n "$unchanged" ]; then
					echo "  Copying: $file (unchanged)"
					cp "$_cdt_srcdir/$file" "$_cdt_destdir/$dir"
				else
					# Set the filters for replacement based on file extension.
					_cdt_alpha_filter=cat
					_cdt_debug_filter=cat
					_cdt_nolib_filter=cat
					_cdt_do_not_package_filter=cat
					_cdt_classic_filter=cat
					case $file in
					*.lua)
						[ -n "$_cdt_alpha" ] && _cdt_alpha_filter="lua_filter alpha"
						[ -n "$_cdt_debug" ] && _cdt_debug_filter="lua_filter debug"
						[ -n "$_cdt_do_not_package" ] && _cdt_do_not_package_filter="do_not_package_filter lua"
						[ -n "$_cdt_classic" ] && _cdt_classic_filter="lua_filter retail"
						;;
					*.xml)
						[ -n "$_cdt_alpha" ] && _cdt_alpha_filter="xml_filter alpha"
						[ -n "$_cdt_debug" ] && _cdt_debug_filter="xml_filter debug"
						[ -n "$_cdt_nolib" ] && _cdt_nolib_filter="xml_filter no-lib-strip"
						[ -n "$_cdt_do_not_package" ] && _cdt_do_not_package_filter="do_not_package_filter xml"
						[ -n "$_cdt_classic" ] && _cdt_classic_filter="xml_filter retail"
						;;
					*.toc)
						_cdt_alpha_filter="toc_filter2 alpha ${_cdt_alpha:-0}"
						_cdt_debug_filter="toc_filter2 debug ${_cdt_debug:-0}"
						_cdt_nolib_filter="toc_filter2 no-lib-strip ${_cdt_nolib:-0}"
						_cdt_do_not_package_filter="toc_filter2 do-not-package ${_cdt_do_not_package:-0}"
						_cdt_classic_filter="toc_filter2 retail ${_cdt_classic:-0}"
						;;
					esac
					# As a side-effect, files that don't end in a newline silently have one added.
					# POSIX does imply that text files must end in a newline.
					set_info_file "$_cdt_srcdir/$file"
					echo "  Copying: $file"
					simple_filter < "$_cdt_srcdir/$file" \
						| $_cdt_alpha_filter \
						| $_cdt_debug_filter \
						| $_cdt_nolib_filter \
						| $_cdt_do_not_package_filter \
						| $_cdt_classic_filter \
						| line_ending_filter \
						> "$_cdt_destdir/$file"
				fi
			fi
		fi
	done
}

###
### Process .pkgmeta to set variables used later in the script.
###

if [ -z "$pkgmeta_file" ]; then
	pkgmeta_file="$topdir/.pkgmeta"
fi

ignore=

parse_ignore() {
	pkgmeta="$1"
	[ -f "$pkgmeta" ] || return 1

	checkpath="$topdir" # paths are relative to the topdir
	copypath=""
	if [ "$2" != "" ]; then
		checkpath=$( dirname "$pkgmeta" )
		copypath="$2/"
	fi

	yaml_eof=
	while [ -z "$yaml_eof" ]; do
		IFS='' read -r yaml_line || yaml_eof="true"
		# Strip any trailing CR character.
		yaml_line=${yaml_line%$carriage_return}
		case $yaml_line in
		[!\ ]*:*)
			# Split $yaml_line into a $yaml_key, $yaml_value pair.
			yaml_keyvalue "$yaml_line"
			# Set the $pkgmeta_phase for stateful processing.
			pkgmeta_phase=$yaml_key
			;;
		[\ ]*"- "*)
			yaml_line=${yaml_line#"${yaml_line%%[! ]*}"} # trim leading whitespace
			# Get the YAML list item.
			yaml_listitem "$yaml_line"
			if [ "$pkgmeta_phase" = "ignore" ]; then
				pattern=$yaml_item
				if [ -d "$checkpath/$pattern" ]; then
					pattern="$copypath$pattern/*"
				elif [ ! -f "$checkpath/$pattern" ]; then
					# doesn't exist so match both a file and a path
					pattern="$copypath$pattern:$copypath$pattern/*"
				fi
				if [ -z "$ignore" ]; then
					ignore="$pattern"
				else
					ignore="$ignore:$pattern"
				fi
			fi
			;;
		esac
	done < "$pkgmeta"
}
parse_ignore "$pkgmeta_file"

# Checkout the external into a ".checkout" subdirectory of the final directory.
checkout_external() {
	_external_dir=$1
	_external_uri=$2
	_external_tag=$3
	_external_type=$4
	_external_slug=$5
	_external_extra_type=$6

	_cqe_checkout_dir="$checkoutdir/$_external_dir"
	mkdir -p "$_cqe_checkout_dir"
	echo
	if [ "$_external_type" = "git" ]; then
		if [ -z "$_external_tag" ]; then
			echo "Fetching latest version of external $_external_uri"
			git clone -q --depth 1 "$_external_uri" "$_cqe_checkout_dir" || return 1
		elif [ "$_external_tag" != "latest" ]; then
			echo "Fetching $_external_extra_type \"$_external_tag\" from external $_external_uri"
			if [ "$_external_extra_type" = "commit" ]; then
				git clone -q "$_external_uri" "$_cqe_checkout_dir" || return 1
				git -C "$_cqe_checkout_dir" checkout -q "$_external_tag" || return 1
			else
				git -c advice.detachedHead=false clone -q --depth 1 --branch "$_external_tag" "$_external_uri" "$_cqe_checkout_dir" || return 1
			fi
		else # [ "$_external_tag" = "latest" ]; then
			git clone -q --depth 50 "$_external_uri" "$_cqe_checkout_dir" || return 1
			_external_tag=$( git -C "$_cqe_checkout_dir" for-each-ref refs/tags --sort=-creatordate --format=%\(refname:short\) --count=1 )
			if [ -n "$_external_tag" ]; then
				echo "Fetching tag \"$_external_tag\" from external $_external_uri"
				git -C "$_cqe_checkout_dir" checkout -q "$_external_tag" || return 1
			else
				echo "Fetching latest version of external $_external_uri"
			fi
		fi

		# pull submodules
		git -C "$_cqe_checkout_dir" submodule -q update --init --recursive || return 1

		set_info_git "$_cqe_checkout_dir"
		echo "Checked out $( git -C "$_cqe_checkout_dir" describe --always --tags --long )" #$si_project_abbreviated_hash
	elif [ "$_external_type" = "svn" ]; then
		if [[ $external_uri == *"/trunk" ]]; then
			_cqe_svn_trunk_url=$_external_uri
			_cqe_svn_subdir=
		else
			_cqe_svn_trunk_url="${_external_uri%/trunk/*}/trunk"
			_cqe_svn_subdir=${_external_uri#${_cqe_svn_trunk_url}/}
		fi

		if [ -z "$_external_tag" ]; then
			echo "Fetching latest version of external $_external_uri"
			svn checkout -q "$_external_uri" "$_cqe_checkout_dir" || return 1
		else
			_cqe_svn_tag_url="${_cqe_svn_trunk_url%/trunk}/tags"
			if [ "$_external_tag" = "latest" ]; then
				_external_tag=$( svn log --verbose --limit 1 "$_cqe_svn_tag_url" 2>/dev/null | awk '/^   A \/tags\// { print $2; exit }' | awk -F/ '{ print $3 }' )
				if [ -z "$_external_tag" ]; then
					_external_tag="latest"
				fi
			fi
			if [ "$_external_tag" = "latest" ]; then
				echo "No tags found in $_cqe_svn_tag_url"
				echo "Fetching latest version of external $_external_uri"
				svn checkout -q "$_external_uri" "$_cqe_checkout_dir" || return 1
			else
				_cqe_external_uri="${_cqe_svn_tag_url}/$_external_tag"
				if [ -n "$_cqe_svn_subdir" ]; then
					_cqe_external_uri="${_cqe_external_uri}/$_cqe_svn_subdir"
				fi
				echo "Fetching tag \"$_external_tag\" from external $_cqe_external_uri"
				svn checkout -q "$_cqe_external_uri" "$_cqe_checkout_dir" || return 1
			fi
		fi
		set_info_svn "$_cqe_checkout_dir"
		echo "Checked out r$si_project_revision"
	elif [ "$_external_type" = "hg" ]; then
		if [ -z "$_external_tag" ]; then
			echo "Fetching latest version of external $_external_uri"
			hg clone -q "$_external_uri" "$_cqe_checkout_dir" || return 1
		elif [ "$_external_tag" != "latest" ]; then
			echo "Fetching $_external_extra_type \"$_external_tag\" from external $_external_uri"
			hg clone -q --updaterev "$_external_tag" "$_external_uri" "$_cqe_checkout_dir" || return 1
		else # [ "$_external_tag" = "latest" ]; then
			hg clone -q "$_external_uri" "$_cqe_checkout_dir" || return 1
			_external_tag=$( hg --cwd "$_cqe_checkout_dir" log -r . --template '{latesttag}' )
			if [ -n "$_external_tag" ]; then
				echo "Fetching tag \"$_external_tag\" from external $_external_uri"
				hg --cwd "$_cqe_checkout_dir" update -q "$_external_tag"
			else
				echo "Fetching latest version of external $_external_uri"
			fi
		fi
		set_info_hg "$_cqe_checkout_dir"
		echo "Checked out r$si_project_revision"
	else
		echo "Unknown external: $_external_uri" >&2
		return 1
	fi
	# Copy the checkout into the proper external directory.
	(
		cd "$_cqe_checkout_dir" || return 1
		# Set the slug for external localization, if needed.
		# Note: We don't actually do localization since we need the project id and
		# the only way to convert slug->id would be to scrape the project page :\
		slug= #$_external_slug
		project_site=
		if [[ "$_external_uri" == *"wowace.com"* || "$_external_uri" == *"curseforge.com"* ]]; then
			project_site="https://wow.curseforge.com"
		fi
		# If a .pkgmeta file is present, process it for an "ignore" list.
		parse_ignore "$_cqe_checkout_dir/.pkgmeta" "$_external_dir"
		# Remove old external directory
		if [ -e "$topdir/$_external_dir" ]; then
			if [ -d "$topdir/$_external_dir" ]; then
				rm -rf "$topdir/$_external_dir"
			else
				echo "$topdir/$_external_dir is not a directory"
				return 1
			fi
		fi
		copy_directory_tree -dnp -i "$ignore" "$_cqe_checkout_dir" "$topdir/$_external_dir"
	)
	# Remove the ".checkout" subdirectory containing the full checkout.
	if [ -d "$_cqe_checkout_dir" ]; then
		rm -fr "$_cqe_checkout_dir"
	fi
}

external_pids=()

external_dir=
external_uri=
external_tag=
external_type=
external_slug=
external_extra_type=
process_external() {
	if [ -n "$external_dir" ] && [ -n "$external_uri" ]; then
		# convert old curse repo urls
		case $external_uri in
			*git.curseforge.com*|*git.wowace.com*)
				external_type="git"
				# git://git.curseforge.com/wow/$slug/mainline.git -> https://repos.curseforge.com/wow/$slug
				external_uri=${external_uri%/mainline.git}
				external_uri="https://repos${external_uri#*://git}"
				;;
			*svn.curseforge.com*|*svn.wowace.com*)
				external_type="svn"
				# svn://svn.curseforge.com/wow/$slug/mainline/trunk -> https://repos.curseforge.com/wow/$slug/trunk
				external_uri=${external_uri/\/mainline/}
				external_uri="https://repos${external_uri#*://svn}"
				;;
			*hg.curseforge.com*|*hg.wowace.com*)
				external_type="hg"
				# http://hg.curseforge.com/wow/$slug/mainline -> https://repos.curseforge.com/wow/$slug
				external_uri=${external_uri%/mainline}
				external_uri="https://repos${external_uri#*://hg}"
				;;
			svn:*)
				# just in case
				external_type="svn"
				;;
			*)
				if [ -z "$external_type" ]; then
					external_type="git"
				fi
				;;
		esac

		if [[ $external_uri == "https://repos.curseforge.com/wow/"* || $external_uri == "https://repos.wowace.com/wow/"* ]]; then
			if [ -z "$external_slug" ]; then
				external_slug=${external_uri#*/wow/}
				external_slug=${external_slug%%/*}
			fi

			# check if the repo is svn
			_svn_path=${external_uri#*/wow/$external_slug/}
			if [[ "$_svn_path" == "trunk"* ]]; then
				external_type="svn"
			elif [[ "$_svn_path" == "tags/"* ]]; then
				external_type="svn"
				# change the tag path into the trunk path and use the tag var so it gets logged as a tag
				external_tag=${_svn_path#tags/}
				external_tag=${external_tag%%/*}
				external_uri="${external_uri%/tags*}/trunk${_svn_path#tags/$external_tag}"
			fi
		fi

		echo "Fetching external: $external_dir"
		(
			output_file="$checkoutdir/.${RANDOM}.externalout"
			checkout_external "$external_dir" "$external_uri" "$external_tag" "$external_type" "$external_slug" "$external_extra_type" &> "$output_file"
			status=$?
			echo "$(<"$output_file")"
			rm -f "$output_file" 2>/dev/null
			exit $status
		) &
		external_pids+=($!)
	fi
	external_dir=
	external_uri=
	external_tag=
	external_type=
	external_slug=
	external_extra_type=
}

# Don't leave extra files around if exited early
kill_externals() {
	rm -f "$releasedir"/.*.externalout
	kill 0
}
trap kill_externals INT

if [ -f "$pkgmeta_file" ]; then
	nolib_exclude=
	yaml_eof=
	while [ -z "$yaml_eof" ]; do
		IFS='' read -r yaml_line || yaml_eof="true"
		# Strip any trailing CR character.
		yaml_line=${yaml_line%$carriage_return}
		case $yaml_line in
		[!\ ]*:*)
			# Started a new section, so checkout any queued externals.
			process_external
			# Split $yaml_line into a $yaml_key, $yaml_value pair.
			yaml_keyvalue "$yaml_line"
			# Set the $pkgmeta_phase for stateful processing.
			pkgmeta_phase=$yaml_key
			;;
		" "*)
			yaml_line=${yaml_line#"${yaml_line%%[! ]*}"} # trim leading whitespace
			case $yaml_line in
			"- "*)
				;;
			*:*)
				# Split $yaml_line into a $yaml_key, $yaml_value pair.
				yaml_keyvalue "$yaml_line"
				case $pkgmeta_phase in
				externals)
					case $yaml_key in
					url) external_uri=$yaml_value ;;
					tag)
						external_tag=$yaml_value
						external_extra_type=$yaml_key
						;;
					branch)
						external_tag=$yaml_value
						external_extra_type=$yaml_key
						;;
					commit)
						external_tag=$yaml_value
						external_extra_type=$yaml_key
						;;
					type) external_type=$yaml_value ;;
					curse-slug) external_slug=$yaml_value ;;
					*)
						# Started a new external, so checkout any queued externals.
						process_external

						external_dir=$yaml_key
						nolib_exclude="$nolib_exclude $pkgdir/$external_dir/*"
						if [ -n "$yaml_value" ]; then
							external_uri=$yaml_value
							# Immediately checkout this fully-specified external.
							process_external
						fi
						;;
					esac
					;;
				esac
				;;
			esac
			;;
		esac
	done < "$pkgmeta_file"
	# Reached end of file, so checkout any remaining queued externals.
	process_external

	if [ -n "$nolib_exclude" ]; then
		echo
		echo "Waiting for externals to finish..."
		for i in ${!external_pids[*]}; do
			if ! wait "${external_pids[i]}"; then
				_external_error=1
			fi
		done
		if [ -n "$_external_error" ]; then
			echo
			echo "There was an error fetching externals :(" >&2
			exit 1
		fi
		echo
	fi
fi

# Restore the signal handlers
trap - INT

# Remove the staging directory.
rm -rf $checkoutdir 2>/dev/null

echo "Fetch externals completed"
