import React from 'react';
import Link from '@docusaurus/Link';
import Layout from '@theme/Layout';

export default function Home(): React.JSX.Element {
    return (
        <Layout title="GoRouter Modular" description="Dependency injection and route management">
            <main style={{ padding: 0 }}>
                <div
                    style={{
                        position: 'relative',
                        width: '100%',
                        height: 'calc(100vh - 60px)',
                        overflow: 'hidden',
                    }}
                >
                    <img
                        src="/home/img/banner.png"
                        alt="Go Router Modular banner"
                        style={{ width: '100%', height: '100%', objectFit: 'cover' }}
                    />

                    <div
                        style={{
                            position: 'absolute',
                            inset: 0,
                            display: 'flex',
                            alignItems: 'flex-end',
                            justifyContent: 'center',
                            paddingBottom: 32,
                        }}
                    >
                        <Link
                            className="button button--lg ctaNeon"
                            style={{
                                background: '#ffffff',
                                color: '#0b0b0b',
                            }}
                            to="/home/docs/intro"
                        >
                            GO DOCS
                        </Link>
                    </div>
                </div>
            </main>
        </Layout>
    );
}


