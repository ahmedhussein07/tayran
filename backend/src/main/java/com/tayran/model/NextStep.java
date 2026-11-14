package com.tayran.model;

/** Where the app goes after sign-in, and on every launch with a stored session. */
public enum NextStep {
    /** New user, or a user with no name yet. */
    NAME,
    /** Has a name but no address yet. */
    ADDRESS,
    /** Has a name and a default address. */
    HOME
}
