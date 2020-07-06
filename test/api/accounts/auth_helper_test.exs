defmodule Api.Accounts.AuthHelperTest do
  @moduledoc """
    Test Helper Module for Account Authentication
  """

  use Api.DataCase
  alias Api.Repo.Seeder
  alias Api.Accounts.{AuthHelper, User}
  alias Api.Tenants

  setup do
    Seeder.seed()

    user = Repo.get_by!(User, email: "eike.wiewiorra@lotta.schule")
    web_tenant = Tenants.get_tenant_by_slug!("web")

    {:ok,
     %{
       web_tenant: web_tenant,
       user: user
     }}
  end

  describe "login_with_username_pass/2" do
    test "should login the user with correct username and password" do
      assert {:ok, _} =
               AuthHelper.login_with_username_pass("eike.wiewiorra@lotta.schule", "test123")
    end

    test "should not login when the password is wrong" do
      assert {:error, "Falsche Zugangsdaten."} ==
               AuthHelper.login_with_username_pass("eike.wiewiorra@lotta.schule", "ABCSichersPW")
    end

    test "should login the user when he gave the email in mixed case" do
      assert {:ok, _} =
               AuthHelper.login_with_username_pass("Eike.WieWiorra@lotta.schule", "test123")
    end
  end
end