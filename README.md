# findmed_demo

FindMed demo application.

## Admin Branch Management

Admins can now Create, Read, Update, and Delete pharmacy branches directly from the Admin Dashboard:

- Open the drawer and select **Manage Branches** to view all branches.
- Use **New Branch** or the **Create Branch** drawer item to add a branch.
- Tap the edit icon to update name, address, phone, or company.
- Tap the delete icon to remove a branch (its inventory and manager assignments are also removed).
- Use the Home (house) icon in the AppBar to return to the Chains page.

### Data Integrity

Deleting a branch automatically removes:

- Inventory rows for that branch
- Branch manager assignments

Medicines themselves are retained (they may be reused or reassigned later).

### Testing Steps

1. Login as admin (`admin@gmail.com` / `demo123`).
2. Create a branch and confirm it appears in Manage Branches and Chains (Home).
3. Edit the branch (change name) and verify updated label on Home after reopening chains list.
4. Delete the branch and confirm it is removed from both Manage Branches and Chains.

### Notes

If Chains page does not immediately reflect changes, perform a hot reload or revisit Home to trigger a fresh branch query.
