#!/bin/sh

test_description='verify safe.directory checks while running as root'

. ./test-lib.sh

if [ "$IKNOWWHATIAMDOING" != "YES" ]; then
	skip_all="You must set env var IKNOWWHATIAMDOING=YES in order to run this test"
	test_done
fi

is_root() {
	test -n "$1" && CMD="sudo -n"
	test $($CMD id -u) = $(id -u root)
}

test_lazy_prereq SUDO '
	is_root sudo &&
	! sudo grep -E '^[^#].*secure_path' /etc/sudoers
'

test_lazy_prereq ROOT '
	is_root
'

test_expect_success SUDO 'setup' '
	sudo rm -rf root &&
	mkdir -p root/r &&
	sudo chown root root &&
	(
		cd root/r &&
		git init
	)
'

test_expect_success SUDO 'sudo git status as original owner' '
	(
		cd root/r &&
		git status &&
		sudo git status
	)
'

test_expect_success SUDO 'setup root owned repository' '
	sudo mkdir -p root/p &&
	sudo git init root/p
'

test_expect_success SUDO,!ROOT 'can access if owned by root' '
	(
		cd root/p &&
		test_must_fail git status
	)
'

test_expect_success SUDO,!ROOT 'can access with sudo' '
	# fail to access using sudo
	(
		# TODO: test_must_fail missing functionality
		cd root/p &&
		! sudo git status
	)
'

test_expect_success SUDO 'can access with workaround' '
	# provide explicit GIT_DIR
	(
		cd root/p &&
		sudo sh -c "
			GIT_DIR=.git GIT_WORK_TREE=. git status
		"
	) &&
	# discard SUDO_UID
	(
		cd root/p &&
		sudo sh -c "
			unset SUDO_UID &&
			git status
		"
	)
'

test_expect_success SUDO 'cleanup' '
	sudo rm -rf root
'

test_done
