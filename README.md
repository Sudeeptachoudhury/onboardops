OnboardOps Provisioning Kit
RHEL Foundations — RH124 Project
1. Business Case

An IT services company in Pune onboards approximately 20 trainees every month. User account creation is performed manually by different engineers, which can result in inconsistent permissions.

Common problems include:

Trainees receiving unnecessary sudo privileges.
Shared project files not being editable by other team members.
Incorrect group ownership of shared files.
Inconsistent password policies.
Manual provisioning taking unnecessary time.

The goal of this project is to create a standardized Linux provisioning setup that provides every new joiner with a consistent and correctly-permissioned environment.

2. Problem Statement

Build a standardized user and access provisioning setup for a project team.

The solution must:

Create a devteam group.
Create three users: devuser1, devuser2, and devuser3.
Add all three users to devteam as a supplementary group.
Configure home directories and Bash login shells.
Enforce a 60-day maximum password age.
Configure a 7-day password expiry warning.
Force users to change their password at first login.
Grant full sudo access to exactly one user.
Deny sudo access to the other two users.
Create /shared/project.
Configure SGID on the shared directory.
Configure the sticky bit on the shared directory.
Configure umask 0007.
Provide verification evidence demonstrating that the configuration works.
3. Solution Approach

The project uses a Bash provisioning script named provision.sh.

The script performs the following tasks:

Checks that it is being executed as root.
Verifies required Linux commands are available.
Creates the devteam group if it does not already exist.
Creates the three required users if they do not already exist.
Adds all users to devteam.
Configures the password aging policy.
Sets user passwords interactively.
Creates a sudoers drop-in for devuser1.
Creates /shared/project.
Configures SGID and sticky-bit permissions.
Configures umask 0007 for all three users.
Performs basic verification at the end of the provisioning process.
4. User and Group Configuration
Group
devteam

Users
User	Primary Purpose	Sudo
devuser1	Project administrator	Yes
devuser2	Project team member	No
devuser3	Project team member	No

All three users are members of devteam as a supplementary group.

Verification:

id devuser1
id devuser2
id devuser3

5. Password Policy

The provisioning script applies the following password policy:

Maximum password age : 60 days
Warning period       : 7 days
First login          : Password change required


The policy is configured using:

chage -M 60 -W 7 -d 0 <username>


Verification:

chage -l devuser1
chage -l devuser2
chage -l devuser3

6. Sudo Configuration

Only devuser1 receives full sudo privileges.

The sudo configuration is created at:

/etc/sudoers.d/onboardops


Configuration:

devuser1 ALL=(ALL) ALL


The sudoers file is validated using:

visudo -cf /etc/sudoers.d/onboardops

Sudo verification

devuser1:

sudo -l


Expected result: the user is permitted to run sudo commands.

devuser2:

sudo -l


Expected result: the user is not permitted to run sudo commands.

devuser3:

sudo -l


Expected result: the user is not permitted to run sudo commands.

7. Shared Project Directory

The shared directory is:

/shared/project


It is owned by:

root:devteam


The directory permissions are configured using:

chmod 3770 /shared/project

Permission breakdown
3    = SGID + sticky bit
770  = owner/group full access, others no access


The SGID bit ensures newly created files and directories inherit the devteam group.

The sticky bit prevents users from deleting files owned by other users in the shared directory.

Verification:

ls -ld /shared/project


Expected permission pattern:

drwxrws--T

8. Default Permissions and Umask

The provisioning script configures:

umask 0007


for all three users.

This allows group collaboration while preventing access by users outside the owner and group.

Verification:

grep -n "umask 0007" /home/devuser1/.bashrc
grep -n "umask 0007" /home/devuser2/.bashrc
grep -n "umask 0007" /home/devuser3/.bashrc

9. Verification

The verification output is stored in:

verification.txt


The file contains evidence for:

devteam group membership.
User IDs and group membership.
Password aging configuration.
Home directory ownership.
Shared directory permissions.
Sudoers configuration.
Sudoers syntax validation.
User umask configuration.
Sudo access testing.

The verification file was generated using system commands such as:

id
ls -ld
chage -l
visudo -c

10. Troubleshooting

During implementation, several real-world issues were encountered and documented in commands.txt.

Examples include:

Attempting to create an existing group.
Attempting to create an existing user.
Vim returning E212: Can't open file for writing.
A mistyped filesystem path.
Attempting to create an already-existing test directory.
Running sudo -l through a non-interactive su -c command without a terminal.
Managing nested su sessions.

The failures and their resolutions are documented in:

commands.txt


This demonstrates the troubleshooting process rather than only documenting successful commands.

11. Repository Structure
onboardops/
├── provision.sh
├── verification.txt
├── commands.txt
├── README.md
└── screenshots/

File descriptions
File	Description
provision.sh	Main provisioning script
verification.txt	Verification command output
commands.txt	Commands used during implementation, including failures
README.md	Project documentation
screenshots/	Evidence screenshots
12. How to Run

The provisioning script must be executed as root.

chmod +x provision.sh
./provision.sh


The script interactively requests passwords for the three users.

After provisioning, verification can be performed using:

cat verification.txt


Additional system verification commands include:

id devuser1
id devuser2
id devuser3

chage -l devuser1
chage -l devuser2
chage -l devuser3

ls -ld /shared/project

cat /etc/sudoers.d/onboardops

visudo -c

13. Proof of Work

The solution was tested by switching between the three users and verifying:

Group membership.
Password policy.
Sudo permissions.
Shared directory access.
Group inheritance.
Sticky-bit behavior.
Default file permissions.

Screenshots of the verification results will be stored in the screenshots/ directory.

14. Demo Video

A short demonstration video will show:

Running the provisioning script.
Verifying the users and group.
Checking password aging.
Checking sudo permissions.
Testing shared directory access.
Demonstrating SGID group inheritance.
Demonstrating sticky-bit protection.
Reviewing the verification output.

Video link:

To be added

15. Skills Demonstrated

This project demonstrates practical knowledge of:

Linux user management.
Linux group management.
Password aging with chage.
Sudo and sudoers configuration.
Linux file permissions.
SGID.
Sticky bit.
Umask.
Bash scripting.
Shell troubleshooting.
Verification and documentation.
16. RH124 Syllabus Coverage

The project covers concepts related to:

User and group administration.
File permissions and ownership.
Special permissions.
Sudo configuration.
Password management.
Bash command-line administration.
System administration troubleshooting.
17. Conclusion

The OnboardOps Provisioning Kit provides a repeatable method for provisioning project users with standardized access controls.

The setup ensures that all project users share a common devteam group, only the designated administrator receives sudo access, password aging policies are consistently applied, and the shared project directory supports controlled team collaboration.
