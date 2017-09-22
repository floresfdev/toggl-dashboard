Code book
=========

## Toggl: Export to CSV

The `.csv` file used in this application is exported from Toggl:

1. Login into the [app](https://www.toggl.com/app/) => The application is loaded.
2. Sidebar: Click on **Reports** => The **Summary** report is shown by default.
3. Top navigation bar: Click on **Detailed** => The weekly **Detailed report** is shown by default.
4. Period selector on the right: Click and select the report start/end date or one of the predefined options, e.g. **Last Month** => The **Detailed report** is updated.
5. Click on button **Export &#8595;** and select option **Download as CSV** => Dialog to save the file is shown.
6. Click on **Save** => `.csv` file is saved.


## Code book

- `User`: Name of the user. Type: Character.
- `Email`: Email of the user. Type: Character, valid email address.
- `Client`: Name of the client related to the time entry. Type: Character, field can be empty.
- `Project`: Name of the project related to the time entry. Type: Character, field can be empty.
- `Task`: *Empty (free plan)*
- `Description`: Time entry description. Type: Character, field can be empty (extreme case)
- `Billable`: Is the time entry billable in Toggl? Type: Character, valid values: `Yes` and `No`.
- `Start date`: Start date of the time entry. Type: Character, format: `yyyy-mm-dd`.
- `Start time`: Start time of the time entry. Type: Character, format: `hh:mm:ss`.
- `End date`: End date of the time entry. Type: Character, format: `yyyy-mm-dd`.
- `End time`: End time of the time entry. Type: Character, format: `hh:mm:ss`.
- `Duration`: Duration of the time entry. Type: Character, format: `hh:mm:ss`.
- `Tags`: Tag list of the time entry. Type: Character, field can be empty, format: List of strings, comma separated, between double quotation marks (e.g. `"Tag1, Tag2, Tag3"`).
- `Amount ()`: *Empty (free plan). Depends on the `Billable` field*