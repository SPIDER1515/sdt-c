defmodule NA.Adj do
  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      supervisor(NA.DB.Repo.Drug, [[use_cache: false]]),
      supervisor(NA.DB.Repo.Patient, [[use_cache: false]]),
      supervisor(NA.DB.Repo.PreferredDrugList, [[use_cache: false]]),
      supervisor(NA.DB.Repo.Pharmacy, [[use_cache: false]]),
      supervisor(NA.DB.Repo.PharmacyPanel, [[use_cache: true]]),
      supervisor(NA.DB.Repo.Mac, [[use_cache: false]]),
      supervisor(NA.DB.Repo.Groups, [[use_cache: false]]),
      supervisor(NA.DB.Repo.BenefitList, [[use_cache: false]]),
      supervisor(NA.DB.Repo.PharmacyTax, [[use_cache: false]]),
      supervisor(NA.DB.Repo.Plan, [[use_cache: false]]),
      supervisor(NA.DB.Repo.Misc, [[use_cache: false]]),
      supervisor(NA.DB.Repo.PriorAuthorization, [[use_cache: false]]),
      supervisor(NA.DB.Repo.Modifiers, [[use_cache: false]]),
      supervisor(NA.DB.Repo.Prescriber, [[use_cache: false]]),
      supervisor(NA.DB.Repo.PrescriberPanel, [[use_cache: true]])
    ]

    opts = [strategy: :one_for_one, name: NA.Adj.Supervisor]

    Supervisor.start_link(children, opts)
  end
end
