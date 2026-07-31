import {
  isSoleWorkspaceOwner,
  type WorkspaceMemberIdentity,
} from "./sole_workspace_owner.ts";

const ownerId = "7eb71837-0dc9-41c2-af29-07c324d74698";

Deno.test("accepts the one matching workspace member as the owner", () => {
  if (!isSoleWorkspaceOwner([{ user_id: ownerId }], ownerId)) {
    throw new Error("Expected the sole matching member to be accepted");
  }
});

Deno.test("rejects a user who is not the workspace member", () => {
  if (
    isSoleWorkspaceOwner(
      [{ user_id: "268872de-cb74-418b-ad13-dc188dad77aa" }],
      ownerId,
    )
  ) {
    throw new Error("Expected a non-member to be rejected");
  }
});

Deno.test("rejects missing workspace membership", () => {
  const cases: Array<readonly WorkspaceMemberIdentity[] | null | undefined> = [
    undefined,
    null,
    [],
  ];

  for (const memberships of cases) {
    if (isSoleWorkspaceOwner(memberships, ownerId)) {
      throw new Error("Expected missing membership to be rejected");
    }
  }
});

Deno.test("rejects multi-member workspaces even when the requester is a member", () => {
  const memberships = [
    { user_id: ownerId },
    { user_id: "268872de-cb74-418b-ad13-dc188dad77aa" },
  ];

  if (isSoleWorkspaceOwner(memberships, ownerId)) {
    throw new Error("Expected a multi-member workspace to be rejected");
  }
});
