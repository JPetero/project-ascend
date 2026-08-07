/**
 * A `Friendship` row is undirected but stored once — this canonicalizes
 * which user goes in `userAId` vs `userBId` (lexicographically smaller
 * id first) so the same pair never gets two rows and a unique
 * constraint on (userAId, userBId) actually prevents duplicates.
 */
export function canonicalFriendPair(
  userIdA: string,
  userIdB: string,
): { userAId: string; userBId: string } {
  return userIdA < userIdB
    ? { userAId: userIdA, userBId: userIdB }
    : { userAId: userIdB, userBId: userIdA };
}
