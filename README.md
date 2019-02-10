# ipfire-skin-dashboard
A simple and bootstrap powered skin in the form of a dashboard, also adds a dashboard page.

![Alt text](/printscreens/dashboard.png?raw=true "Dashboard")

You can easily re-arrange the widgets on the dashboard to your liking

![Alt text](/printscreens/sorting_item.png?raw=true "Sorting widgets")

I've tried to fit the 'legacy' pages by override some classes, but it needs more work if you want to unify the skin

![Alt text](/printscreens/legacy_page.png?raw=true "Legacy page in skin")

Work list:

[x] Release initial version
[x] Tidy up code
[ ] Map the menu structure and add navigational info (expand menu when for appropriate section and highlight current page)
[x] Make dashboard widgets extensible
[x] Make dashboard widgets sortable
[x] Create notifications widget and cgi
[ ] Tidy up notifications cgi
[ ] Rewrite 'legacy' pages to fit the skin, create scripts to backup the 'legacy' versions
[ ] Create a function to restore the 'legacy' cgi pages (for other skins)
[ ] Create an easy way to add new widgets
[ ] Optimise storage; choose between settings file and SQLite file and argument why
[ ] Create DNS report (unbound statistics)
[ ] Create firewall report (world and link to specific pages for detailed reporting)
[ ] Investigate RRD stats to use for reporting

## Installation instructions
Download the install script:

```
wget https://raw.githubusercontent.com/Saiyato/ipfire-skin-dashboard/master/install-skin.sh
```

Make it executable:
```
chmod +x install-skin.sh
```

Run the installer:
```
./install-skin.sh
```

The installer will download the files and install them in the correct places. If you refresh the WUI, the new skin will be enabled and selected.

Credits: all credits for the installation script and instructions go to TimF (https://github.com/timfprogs).

NOTE: this skin is still in BETA, I will not take any responsibility for damages incurred by using the (new) scripts/pages.
