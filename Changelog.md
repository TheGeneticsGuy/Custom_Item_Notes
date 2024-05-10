

**1.16 Release - May 9th, 2024**

* Stealth release - realized a bug that made it so ONLY in the Cata version the notes would not appear due to a backend change by Blizz.

**1.15 Release - May 9th, 2024**

* CIN no longer uses the itemID as the memory storage reference. The reason this decision was made is because it is more useful to include the string name. This will create a complication if you are using multiple clients, so if t his becomes an issue, I have a way to revert the database if needed, but I don't want to adjust to that yet. However, in the meory I am still storing the itemID in case it ever needs to be called on again and it will be absolutely necessary in the case of a localization effort.

* When you clearAll of a note, or you delete the only existing note, the memory reference of the item will be deleted as it doesn't need to exist. Before it just left an empty table needlessly.

**1.14 Release - May 7th, 2024**

* Updated for 10.2.7 Compatibility

**1.13 Release - May 2nd, 2024**

* Updated for Classic Cata compatibility

**1.12 Release - April 18th, 2024**

* Adding Classic Update support for SOD

**1.11 Release - March 19th, 2024**

* Adding patch 10.2.6 support.

**1.10 Release - February 26th, 2024**

* Adding Season of Discovery Season 2 compatibility

**1.09 Release - January 30th, 2024**

* It appears there is an extra space added at the bottom of tooltips even if all messages deleted. This no longer should happen.

**1.08 Release - January 16th, 2024**

* Compatibility Release for 10.2.5 DF

**1.07 Release - November 7th, 2023**

*Compatibility release for 10.2 DF*

*Compatibility release for 3.4.3 Wrath Classic*

**1.06 Release - September 5th, 2023**

* 10.1.7 Compatibility as well as Classic Era  1.14.4 Hardcore mode compatibility

**1.05 Release - July 11th, 2023**

* 10.1.5 Compatibility as well as Wrath 4.3.2 compatibility

**1.04 Release - May 7th, 2023**

* 10.1 Compatibility.

**1.03 Release - March 27, 2023**

* Fixed an issue where if you used the /cin add or del, it would default it to all be lowercase. It is fixed. Default /cin worked fine, and now this will too.