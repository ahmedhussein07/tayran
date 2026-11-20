package com.tayran.model.order;

/** OK and REDUCED lines are charged; REMOVED and REPLACED ones are not (the replacement line is). */
public enum LineStatus {
    OK, REDUCED, REMOVED, REPLACED;

    public boolean charged() {
        return this == OK || this == REDUCED;
    }
}
