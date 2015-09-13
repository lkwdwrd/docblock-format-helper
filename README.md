# Dockblock Format Helper

Helps format JS and PHP docblocks so that it is less work to write them.

```
/**
 * short description
 *
 * @return type description
 */
 ```

When you start a docblock by typing '/\*\*' it will fill in the rest of the
block when you hit enter. It will then detect you are in a docblock and
automatically add the '\*' characters when you go to a new line. Finally, when
you are at the end of a docblock and hit return after the '\*/' it will remove
the extra space from your indentation so you can just continue coding.
