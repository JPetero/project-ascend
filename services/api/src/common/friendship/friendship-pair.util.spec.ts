import { canonicalFriendPair } from './friendship-pair.util';

describe('canonicalFriendPair', () => {
  it('puts the lexicographically smaller id first regardless of call order', () => {
    expect(canonicalFriendPair('user-a', 'user-b')).toEqual({
      userAId: 'user-a',
      userBId: 'user-b',
    });
    expect(canonicalFriendPair('user-b', 'user-a')).toEqual({
      userAId: 'user-a',
      userBId: 'user-b',
    });
  });
});
