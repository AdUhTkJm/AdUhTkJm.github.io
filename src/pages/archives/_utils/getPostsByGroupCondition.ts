type GroupKey = string | number | symbol;
type GroupFunction<T> = (item: T, index?: number) => GroupKey;

/**
 * Buckets items by a computed key.
 *
 * Kept generic so both posts and the unified article model can use it.
 */
export function getPostsByGroupCondition<T>(
  posts: T[],
  groupFunction: GroupFunction<T>
) {
  const result: Record<GroupKey, T[]> = {};

  for (let i = 0; i < posts.length; i++) {
    const item = posts[i];
    const groupKey = groupFunction(item, i);

    if (!result[groupKey]) {
      result[groupKey] = [];
    }

    result[groupKey].push(item);
  }

  return result;
}
