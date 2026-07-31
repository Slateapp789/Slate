export type WorkspaceMemberIdentity = {
  user_id?: unknown;
};

/**
 * Workloop V1 has one owner per workspace and no collaborator workflow.
 *
 * Keep this check at destructive server boundaries until the data model gains
 * an explicit, migrated ownership role. Requiring exactly one membership
 * prevents an ordinary workspace member from deleting data owned by others.
 */
export function isSoleWorkspaceOwner(
  memberships: readonly WorkspaceMemberIdentity[] | null | undefined,
  userId: string,
) {
  return memberships?.length === 1 &&
    memberships[0]?.user_id === userId;
}
