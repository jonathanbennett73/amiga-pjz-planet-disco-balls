/* Has rexxsample.library already been made
 * available to ARexx? If not, add it with the
 * "addlib" built-in function. This function takes
 * Three parameters: priority, offset and version.
 * The priority determines the order in which ARexx
 * will ask the library dispatchers if they can handle
 * a certain command. The offset value gives the
 * function offset of the library dispatcher to call.
 * The version specifies which library version to open.
 */

if ~show(l, "rexxsample.library") then do
	if ~addlib("rexxsample.library", 0, -30, 0) then do
		say "Could not add rexxsample.library."
		exit(20)
	end
end

	/* Invoke the "ADD" function. */

say "ADD(17,31) =" add(17,31)

	/* Invoke the "DIV" function with a zero divisor. */

say "DIV(42,0) =" div(42,0)
