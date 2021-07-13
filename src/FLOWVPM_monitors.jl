#=##############################################################################
# DESCRIPTION
    Run time functions to monitor flow metrics. These functions ought to be
    passed to `run_vpm!(...)` through the `runtime_function` optional argument.

# AUTHORSHIP
  * Author    : Eduardo J Alvarez
  * Email     : Edo.AlvarezR@gmail.com
  * Created   : Jul 2021
  * Copyright : Eduardo J Alvarez. All rights reserved.
=###############################################################################


"""
Runtime function that calculates the enstrophy of the particle field, or global
enstrophy of the flow. This is calculated by integrating the local enstrophy
defined as ξ = ω⋅ω / 2

Enstrophy is approximated as 0.5*Σ( ζσ(0) Γ𝑝⋅Γ𝑝 ). This is inaccurate, but is a
quick, dirty, and cheap way of getting an idea of how the enstrophy of the
system may be evolving (see notebook 20210702).
"""
function monitor_enstrophy_Gamma2(pfield, t, dt; save_path=nothing, run_name="",
                                                    suff="enstrophy.log",
                                                    vprintln=(args...)->nothing,
                                                    out=[])

    # Calculate enstrophy
    enstrophy = 0
    for P in iterator(pfield)
        enstrophy += (P.Gamma[1]*P.Gamma[1]
                      + P.Gamma[2]*P.Gamma[2] + P.Gamma[3]*P.Gamma[3]
                                                              ) / P.sigma[1]^3
    end
    enstrophy *= 0.5*pfield.kernel.zeta(0)

    # Print to verbose
    vprintln("enstrophy:\t$(enstrophy)")

    # Save files
    if save_path!=nothing
        fname = run_name*"_"^(length(run_name)!=0)*suff

        # Write to log file
        f = open(joinpath(save_path, fname), "a")
        if t==0 || pfield.nt==0
            println(f, "nt", ",", "t (s)", ",", "enstrophy (m^3/s^2)")
        end
        println(f, pfield.nt, ",", t, ",", enstrophy)
        close(f)

    end

    # Push to output array
    push!(out, enstrophy)

    return false
end

"""
Runtime function that calculates the enstrophy of the particle field, or global
enstrophy of the flow. This is calculated by integrating the local enstrophy
defined as ξ = ω⋅ω / 2

Enstrophy is approximated as 0.5*Σ( Γ𝑝⋅ω(x𝑝) ). This is consistent with
Winckelamns' 1995 CTR report ("Some Progress in LES using the 3-D VPM").
See notebook 20210702.

NOTE: This function assumes that the vorticity field has already been
precalculated, which is true if this function is called after the relaxation
step. DON'T USE THIS MONITOR UNLESS YOU KNOW THAT THIS CONDITION IS MET.
"""
function monitor_enstrophy_Gammaomega(pfield, t, dt; save_path=nothing, run_name="",
                                                    suff="enstrophy.log",
                                                    vprintln=(args...)->nothing,
                                                    out=[])

    if pfield.nt != 0

        # Calculate enstrophy
        enstrophy = 0
        for P in iterator(pfield)
            enstrophy += ( P.Gamma[1]*get_W1(P)
                          + P.Gamma[2]*get_W2(P) + P.Gamma[3]*get_W3(P) )
        end
        enstrophy *= 0.5

        # Print to verbose
        vprintln("enstrophy:\t$(enstrophy)")

        # Save files
        if save_path!=nothing
            fname = run_name*"_"^(length(run_name)!=0)*suff

            # Write to log file
            f = open(joinpath(save_path, fname), "a")
            if t==0 || pfield.nt==1
                println(f, "nt", ",", "t (s)", ",", "enstrophy (m^3/s^2)")
            end
            println(f, pfield.nt, ",", t, ",", enstrophy)
            close(f)

        end

        # Push to output array
        push!(out, enstrophy)

    end

    return false
end
