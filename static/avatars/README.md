# Member profile pictures

Drop image files here (e.g. `Ben.png`, `Grandma.webp`). They are **not** named by user ID.

In **Admin → Users**, set each person's **Avatar file** to the filename (e.g. `Ben.png` or just `Ben`). That value is stored on their profile as `avatar_key` and tied to their **user id**, so if they change their display name later, the same file still applies.

Supported: any extension you include in the key (`.png`, `.jpg`, `.webp`). If you omit the extension, `.png` is assumed.
